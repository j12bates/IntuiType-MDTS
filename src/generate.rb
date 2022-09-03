#!/usr/bin/ruby

=begin

    Copyright 2022 Jacob Bates

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

=end

# TODO - Footnotes
# TODO - Page/Column Breaks
# TODO - Update Header for Nth Order Heading

# TODO - Place Generation in its own Class, Header/Footer can use Macros

# TODO - Tables
# TODO - Break Words that are Too Long for One Line
# TODO - Exact Output for Code Blocks (more than one space)

# TODO - Images/Graphics
# TODO - PDF Output

# TODO - Testing/Debugging (escape sequences in source, things missing from stylesheet, invalid input)

# Other Classes
require_relative "stylesheet.rb"
require_relative "page_setup.rb"

# PostScript Version
puts "%!PS-Adobe-3.0"

# Notice
puts
puts "% This PostScript document was produced using the IntuiType Markdown Typesetter."
puts "% To convert to a PDF, run"
puts "%     ps2pdf FILENAME.ps FILENAME.pdf"
puts "% Direct PDF output has not yet been implemented."
puts

# Unit Conversion Procedures
puts "/in { 72 mul } def"
puts "/mm { 2.83465 mul } def"

# Stylesheet
stylesheet_file = "default"
if ARGV.length >= 2 then stylesheet_file = ARGV[1] end

Stylesheet.load(stylesheet_file)

# Page Setup
PageSetup.standards

# PostScript Template
ps_template = File.open(File.join(__dir__, "template.ps"), "r")
ps_template.each do |line|
    line = line.split("%")[0].lstrip.rstrip
    print line
    if line.length != 0 then print " " end
end
puts
puts

# Header/Footer
PageSetup.header_footer

# Current Block Type/Order
@block_type = nil
@block_order = 0

# Fonts
@italic = false
@bold = false
@mono = false

# Get Font Name
def font_name()

    # If there is one font name, return it
    single_name = Stylesheet.get(@block_type, @block_order, "font_name", false)
    if !single_name.nil?
        name = single_name

    # Otherwise, get a font from the list
    else
        font_names = Stylesheet.get(@block_type, @block_order, "font_names", true)
        name = font_names[(@mono ? 4 : 0) + (@bold ? 2 : 0) + (@italic ? 1 : 0)]

    end

    # Format as PostScript Name
    return "/" + name + " "

end

# Parameters
@font_size = 0
@leading = 0
@column_portions = []

# Update Font from Delimiters (Left or Right)
def update_font(word, left)

    font_changed = false

    # Go through Delimeter Run
    pos = left ? 0 : -1
    while word.length != 0
        case word[pos]

            # Emphasis
            when "*", "_"

                # Double
                if word[pos + (left ? 1 : -1)] == "*" || word[pos + (left ? 1 : -1)] == "_"

                    # Only start emphasis from the left, only end from the right
                    if @bold == !left
                        word.slice!(pos)
                        word.slice!(pos)
                        @bold = left
                        font_changed = true
                    else
                        pos += left ? 2 : -2
                    end

                # Single
                else
                    if @italic == !left
                        word.slice!(pos)
                        @italic = left
                        font_changed = true
                    else
                        pos += left ? 1 : -1
                    end

                end

            # Monospace
            when "`"
                word.slice!(pos)
                @mono = !@mono
                font_changed = true

            # Normal char
            else
                break

        end
    end

    # Only return a font name if we should print it
    return font_changed ? font_name : ""

end

# Place a Word and any Font Changes
def place_word(word)

    # Escape Characters
    word = word.gsub("\\", "\\\\\\\\")
    word = word.gsub("(", "\\(")
    word = word.gsub(")", "\\)")

    # Font Changes
    cur_font = ""
    next_font = ""
    if @block_type != :code_block
        cur_font = update_font(word, true)
        next_font = update_font(word, false)
    end

    # Echo Word as String with any Font Names
    print cur_font + "(" + word + ") " + next_font

end

# Place Multiple Words and Font Changes
def place_words(words)
    words.each do |word|

        # Expand a Macro
        if word.match?(/^\\[a-z0-9-]+$/)
            macro(word[1..-1])

        # Normal Word
        else place_word(word)

        end

    end
end

# Add Words to Block
def add_words(words)

    # Code Blocks are line-by-line
    if @block_type == :code_block
        print font_name
        place_words(words)
        puts "false false false 0 PrintParagraph"

    # Everything else can just deal with normal words
    else
        place_words(words)

    end

    # Headings are only one line
    if @block_type == :heading then end_block end

end

# Indentation Levels
@indent_levels = [0]

# Process One Line
def handle_line(line)

    # Indentation
    spaces = line.length - line.lstrip.length

    # Calculate Level, which may be used for order
    while spaces <= @indent_levels[-1]
        @indent_levels.pop
        if @indent_levels.length == 0 then break end
    end
    @indent_levels.push(spaces)
    indent_level = @indent_levels.length - 1

    # Split into words
    words = line.split

    # Code Block Fence
    if words == ["```"]
        if @block_type != :code_block
            end_block
            start_block(:code_block, 0)
        else
            end_block
        end
        return

    # Continue a Code Block
    elsif @block_type == :code_block
        if words.length > 0
            words[0].insert(0, " " * spaces)
        end

    # Start/Continue a Blockquote
    elsif words[0] == ">"
        if @block_type != :block_quote
            end_block
            start_block(:block_quote, 0)
        end

        words.slice!(0)
        if words.length == 0
            end_block
        end

    # Handle everything else

    # Blank Line
    elsif words.length == 0
        if @block_type != :code_block
            end_block
        end

    # Ignore Macro Definition
    elsif words[0] == "\\_def"
        words = []

    # Heading
    elsif words[0].count("#") == words[0].length && words[0].length >= 1 && words[0].length <= 6
        end_block
        start_block(:heading, words[0].length - 1)
        words.slice!(0)

    # Ordered List Item
    elsif words[0][-1] == "." && (Integer(words[0][0..-2]) rescue false)
        end_block
        start_block(:list_item, indent_level)
        @list_item_prefix = next_list_item_prefix(Integer(words[0][0..-2]))
        words.slice!(0)

    # Unordered List Item
    elsif words[0] == "-" || words[0] == "*" || words[0] == "+"
        end_block
        start_block(:list_item, indent_level)
        @list_item_prefix = next_list_item_prefix(false)
        words.slice!(0)

    # Horizontal Rule
    elsif words[0].count("-") == words[0].length && words[0].length >= 3 && words.length == 1
        end_block
        puts "PrintRule"
        @block_heading = true
        words.slice!(0)

    # Paragraph
    elsif @block_type.nil? || @block_type == :block_quote
        end_block
        start_block(:paragraph, 0)

    end

    # Add words
    add_words(words)

end

# Process Lines
def lines(lines)
    lines.each do |line|
        handle_line(line)
    end
end

# Local Macros
@macros = {}

# Scan for Local Macros
def scan_local_macros(lines)
    lines.each do |line|
        words = line.split

        # Check for Definition
        if words[0] == "\\_def" && words[1].match(/^[a-z0-9-]+$/) && words.length > 2
            @macros[words[1]] = words[2..-1].join(" ")
        end

    end
end

# Process Macro
def macro(key)
    macro = @macros[key]
    if macro.nil? then macro = Stylesheet.get_macro(key) end
    if macro.nil? then return end

    lines(macro.split("\n"))
end

# Set Parameters
def set_parameters(font_size, leading, column_portions)

    # If everything's the same, don't bother with a new section
    if font_size == @font_size && leading == @leading && column_portions == @column_portions then return end

    # Font Size and Leading
    print font_size.to_s + " " + leading.to_s + " "

    # Default Columns
    if column_portions.nil? then column_portions = [1] end

    # Preserve Columns if Possible
    if column_portions == @column_portions
        print "0 "
    else

        # PostScript Array
        print "[ "
        for i in column_portions
            print i.to_s + " "
        end
        print "] "

    end

    # Procedure
    puts "NewSection "

    # Keep Track of New Parameters
    @font_size = font_size
    @leading = leading
    @column_portions = column_portions

end

# List Item Prefix
@list_indices = []
@list_item_prefix = ""
@list_item_prefix_font_name = ""

# Get Next List Item Prefix
def next_list_item_prefix(index)

    # Get rid of any lower-order list indices
    @list_indices = @list_indices[0..@block_order]

    # If the list is ordered and continuing, increment the index
    if @list_indices[@block_order] && index
        @list_indices[@block_order] += 1
        index = @list_indices[@block_order]

    # Otherwise, use the index given
    else
        @list_indices[@block_order] = index

    end

    # Prefix Font Name
    @list_item_prefix_font_name = index ? font_name : "/Symbol"

    # Ordered List Item Prefix
    if index
        case Stylesheet.get(@block_type, @block_order, "numeral", false)
            when "arabic"
                prefix = index.to_s
            when "alph_upcase"
                prefix = ("A".."Z").to_a[index % 26 - 1]
            when "alph_downcase"
                prefix = ("a".."z").to_a[index % 26 - 1]
            else
                prefix = index.to_s
        end
        return prefix + "."

    # Unordered List Item Prefix
    else
        case Stylesheet.get(@block_type, @block_order, "bullet", false)
            when "bullet"
                return "\\267"
            when "star", "asterisk"
                return "\\052"
            when "arrow"
                return "\\256"
            when "arrow_double"
                return "\\336"
            else
                return "\\267"
        end

    end

end

# Status Variables (for spacing and indentation)
@first_block = true
@block_heading = false
@prev_block_heading = false

# Start a Block
def start_block(type, order)

    # Update Block Variables
    @block_type = type
    @block_order = order

    # Update Parameters
    set_parameters(Stylesheet.get(type, order, "font_size", true), Stylesheet.get(type, order, "leading", true), Stylesheet.get(type, order, "column_portions", false))

    # Update Status Variables
    @prev_block_heading = @block_heading
    @block_heading = type == :heading

    # Vertical Spacing
    unless @first_block
        case Stylesheet.get(type, order, "space_above", false)
            when "always"
                print "SpaceLine "
            when "not_after_heading"
                unless @prev_block_heading
                    print "SpaceLine "
                end
            when "never"
        end
    end
    @first_block = false

    # If a list has ended, don't keep track of the index or order
    if type != :list_item
        @list_indices = []
    end

    # Starting Font Name
    if type != :code_block
        print font_name
    end

end

# Get Printing Procedure for Ordinary Blocks
def print_proc()

    # Indentation
    indent = false
    indent1 = false
    case Stylesheet.get(@block_type, @block_order, "indent", false)
        when "always"
            indent1 = true
        when "not_after_heading"
            indent1 = !@prev_block_heading
        when "never"
            indent1 = false
    end

    if @block_type == :block_quote
        indent = true
        indent1 = true
    end

    # Justification/Alignment
    justify = false
    align = 0
    case Stylesheet.get(@block_type, @block_order, "align", false)
        when "left"
            align = 0
        when "center"
            align = 1
        when "right"
            align = 2
        when "justify"
            justify = true
    end

    # Return Procedure with Arguments
    return indent.to_s + " " + indent1.to_s + " " + justify.to_s + " " + align.to_s + " PrintParagraph"

end

# End a Block
def end_block()

    # Printing Procedure
    case @block_type
        when :block_quote
            puts print_proc
        when :heading
            puts print_proc
        when :list_item
            puts @list_item_prefix_font_name + " (" + @list_item_prefix + ") " + @block_order.to_s + " PrintListItem"
        when :paragraph
            puts print_proc
    end

    # Reset to Prevent this from Recurring
    @block_type = nil
    @block_order = 0

end

# Source File
source = File.open(ARGV[0], "r")
lines = source.readlines
lines.each do |line| line.chomp! end

# Local Macros
scan_local_macros(lines)

# Begin Document
puts "Begin"
macro("_begin")

# Process Lines
lines(lines)
end_block

# End Document
macro("_end")
puts "End"
