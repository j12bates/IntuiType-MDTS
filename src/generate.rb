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

# TODO - Both Emphasis Characters
# TODO - Configure Header/Footer Directly

# TODO - Clear Up Behaviour Concerning Missing Stylesheet Settings

# TODO - Headers, Footers, Page Numbers, Draw After Content is Done
# TODO - Stylesheets Can Add Things to Document and Prompt for Custom Content (e.g. memo to/from/subject)
# TODO - Footnotes

# TODO - Images/Graphics
# TODO - PDF Output

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

# Header/Footer
PageSetup.header_footer

# Current Block Type/Order
@cur_block_type = 0
@cur_block_order = 0

# Fonts
@italic = false
@bold = false
@mono = false

# Get Font Name
def font_name()

    # If there is one font name, return it
    single_name = Stylesheet.get(@cur_block_type, @cur_block_order, "font_name")
    if !single_name.nil?
        name = single_name

    # Otherwise, get a font from the list
    else
        font_names = Stylesheet.get(@cur_block_type, @cur_block_order, "font_names")
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

            # (Double) Emphasis
            when "*"
                if word[pos + (left ? 1 : -1)] == "*"

                    # Only start emphasis from the left, only end from the right
                    if @bold == !left
                        word.slice!(pos)
                        word.slice!(pos)
                        @bold = left
                        font_changed = true
                    else
                        pos += left ? 2 : -2
                    end

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
    if @cur_block_type != :code_block
        cur_font = update_font(word, true)
        next_font = update_font(word, false)
    end

    # Echo Word as String with any Font Names
    print cur_font + "(" + word + ") " + next_font

end

# Add Words
def add_words(block_type, block_order, words)

    # Handle a New Block
    if block_type != @cur_block_type || block_order != @cur_block_order
        end_block
        @cur_block_type = block_type
        @cur_block_order = block_order
        start_block
    end

    # Place Words as Strings
    words.each do |word|
        place_word(word)
    end

end

# Indentation Levels
@indent_levels = [0]

# Handle One Line
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
    if words[0] == "```"
        if @cur_block_type == :code_block
            end_block
        else
            add_words(:code_block, 0, [])
        end

    # Handle Line in Code Block
    elsif @cur_block_type == :code_block
        print font_name
        if words.length > 0
            words[0].insert(0, " " * spaces)
        end
        add_words(:code_block, 0, words)
        puts "false false 0 PrintParagraph"

    # Empty Line
    elsif words.length == 0
        end_block

    # Heading
    elsif words[0].count("#") == words[0].length && words[0].length >= 1 && words[0].length <= 6
        order = words[0].length - 1
        words.slice!(0)
        add_words(:heading, order, words)
        end_block

    # Blockquote
    elsif words[0] == ">"
        words.slice!(0)
        if words.length == 0 then end_block end
        add_words(:block_quote, 0, words)

    # Ordered List Item
    elsif words[0][-1] == "." && (Integer(words[0][0..-2]) rescue false)
        end_block
        words[0].slice!(-1)
        add_words(:list_item, indent_level, [])
        @list_item_prefix = next_list_item_prefix(Integer(words[0]))
        words.slice!(0)
        add_words(:list_item, indent_level, words)

    # Unordered List Item
    elsif words[0] == "-" || words[0] == "*" || words[0] == "+"
        end_block
        add_words(:list_item, indent_level, [])
        @list_item_prefix = next_list_item_prefix(false)
        words.slice!(0)
        add_words(:list_item, indent_level, words)

    # Horizontal Rule
    elsif words[0].count("-") == words[0].length && words[0].length >= 3 && words.length == 1
        end_block
        puts "PrintRule"
        @block_heading = true

    # Handle Continuing List Item
    elsif @cur_block_type == :list_item
        add_words(@cur_block_type, @cur_block_order, words)

    # Paragraph
    else
        add_words(:paragraph, 0, words)

    end

end

# Set Parameters
def set_parameters(font_size, leading, column_portions)

    # If everything's the same, don't bother with a new section
    if font_size == @font_size && leading == @leading && column_portions == @column_portions then return end

    # Font Size and Leading
    print font_size.to_s + " " + leading.to_s + " "

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
    @list_indices = @list_indices[0..@cur_block_order]

    # If the list is ordered and continuing, increment the index
    if @list_indices[@cur_block_order] && index
        @list_indices[@cur_block_order] += 1
        index = @list_indices[@cur_block_order]

    # Otherwise, use the index given
    else
        @list_indices[@cur_block_order] = index

    end

    # Prefix Font Name
    @list_item_prefix_font_name = index ? font_name : "/Symbol"

    # Ordered List Item Prefix
    if index
        case Stylesheet.get(@cur_block_type, @cur_block_order, "numeral")
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
        case Stylesheet.get(@cur_block_type, @cur_block_order, "bullet")
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
def start_block()

    # Update Parameters
    set_parameters(Stylesheet.get(@cur_block_type, @cur_block_order, "font_size"), Stylesheet.get(@cur_block_type, @cur_block_order, "leading"), Stylesheet.get(@cur_block_type, @cur_block_order, "column_portions"))

    # Update Status Variables
    @prev_block_heading = @block_heading
    @block_heading = @cur_block_type == :heading

    # Vertical Spacing
    unless @first_block
        case Stylesheet.get(@cur_block_type, @cur_block_order, "space_above")
            when "always"
                print "NextLine "
            when "not_after_heading"
                unless @prev_block_heading
                    print "NextLine "
                end
        end
    end
    @first_block = false

    # If a list has ended, don't keep track of the index or order
    if @cur_block_type != :list_item
        @list_indices = []
    end

    # Starting Font Name
    if @cur_block_type != :code_block
        print font_name
    end

end

# Get Printing Procedure for Ordinary Blocks
def print_proc()

    # Indentation
    indent = false
    case Stylesheet.get(@cur_block_type, @cur_block_order, "indent")
        when "always"
            indent = true
        when "not_after_heading"
            indent = !@prev_block_heading
    end

    # Justification/Alignment
    justify = false
    align = 0
    case Stylesheet.get(@cur_block_type, @cur_block_order, "align")
        when "center"
            align = 1
        when "right"
            align = 2
        when "justify"
            justify = true
    end

    # Return Procedure with Arguments
    return indent.to_s + " " + justify.to_s + " " + align.to_s + " PrintParagraph"

end

# End a Block
def end_block()

    # Printing Procedure
    case @cur_block_type
        when :block_quote
            puts "PrintBlockQuote"
        when :heading
            puts print_proc
        when :list_item
            puts @list_item_prefix_font_name + " (" + @list_item_prefix + ") " + @cur_block_order.to_s + " PrintListItem"
        when :paragraph
            puts print_proc
    end

    # Reset to Prevent this from Recurring
    @cur_block_type = 0
    @cur_block_order = 0

end

# Source File
source = File.open(ARGV[0], "r")

# Begin Document
puts "Begin"

# Loop Through Lines
source.each do |line|

    # Handle Line
    handle_line(line)

end
end_block

# End Document
puts "End"
