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

# TODO - Clear Up Behaviour Concerning Missing Stylesheet Settings

# TODO - Headers, Footers, Page Numbers, Draw After Content is Done
# TODO - Stylesheets Can Add Things to Document and Prompt for Custom Content (e.g. memo to/from/subject)
# TODO - Footnotes

# TODO - Reorganize Ruby Code into Multiple Source Files

# TODO - Images/Graphics
# TODO - PDF Output

# PostScript Version
puts "%!PS-Adobe-3.0"

# Notice
puts
puts "% This PostScript document was produced using the IntuiType Markdown Typesetter."
puts "% To convert to a PDF, run"
puts "%     ps2pdf FILENAME.ps FILENAME.pdf"
puts "% Direct PDF output has not yet been implemented."
puts

# Stylesheet
require "json"

stylesheet_file = "default"

if ARGV.length >= 2
    stylesheet_file = ARGV[1]
end

@stylesheet = JSON.parse(File.read(File.join(__dir__, "res", stylesheet_file + ".json")))

# Unit Conversion Procedures
puts "/in { 72 mul } def"
puts "/mm { 2.83465 mul } def"

# Page Size
page_units = "in"
page_size = @stylesheet["page"]["size"]
page_size_dimensions = {"width" => 8.5, "height" => 11}

# Handle Preset Size
if (page_size.is_a? String)
    case page_size
        when "letter"
            page_units = "in"
            page_size_dimensions["width"] = 8.5
            page_size_dimensions["height"] = 11
        when "a4"
            page_units = "mm"
            page_size_dimensions["width"] = 210
            page_size_dimensions["height"] = 297
    end

# Handle Custom Size
elsif (page_size.is_a? Hash) && (page_size["width"].is_a? Numeric) && (page_size["height"].is_a? Numeric) && (page_size["units"] == "in" || page_size["units"] == "mm")
    page_size_dimensions = page_size
    page_units = page_size["units"]

end

puts "/PageWidth " + page_size_dimensions["width"].to_s + " " + page_units + " def"
puts "/PageHeight " + page_size_dimensions["height"].to_s + " " + page_units + " def"

# Standard Length (used in default margin, indent, and gutter)
case page_units
    when "in"
        page_default = 1.0
    when "mm"
        page_default = 25.0
end

# Page Margin
page_margin = @stylesheet["page"]["margin"]
page_margin_sides = {"left" => page_default, "right" => page_default, "top" => page_default, "bottom" => page_default}

# Handle Constant Margin
if (page_margin.is_a? Numeric)
    page_margin_sides.keys.each do |side|
        page_margin_sides[side] = page_margin
    end

# Handle Varying Margin
elsif (page_margin.is_a? Hash)

    # X and Y
    if (page_margin["x"].is_a? Numeric) && (page_margin["y"].is_a? Numeric)
        page_margin_sides["left"] = page_margin_sides["right"] = page_margin["x"]
        page_margin_sides["top"] = page_margin_sides["bottom"] = page_margin["y"]

    # All Sides
    elsif (page_margin["left"].is_a? Numeric) && (page_margin["right"].is_a? Numeric) && (page_margin["top"].is_a? Numeric) && (page_margin["bottom"].is_a? Numeric)
        page_margin_sides = page_margin

    end

end

puts "/MarginLeft " + page_margin_sides["left"].to_s + " " + page_units + " def"
puts "/MarginRight " + page_margin_sides["right"].to_s + " " + page_units + " def"
puts "/MarginTop " + page_margin_sides["top"].to_s + " " + page_units + " def"
puts "/MarginBottom " + page_margin_sides["bottom"].to_s + " " + page_units + " def"

# Other Document Standards
standard_indent = @stylesheet["page"]["indent"]
standard_gutter = @stylesheet["page"]["gutter"]

unless (standard_indent.is_a? Numeric) then standard_indent = page_default / 2 end
unless (standard_gutter.is_a? Numeric) then standard_gutter = page_default / 2 end

puts "/Indent " + standard_indent.to_s + " " + page_units + " def"
puts "/Gutter " + standard_gutter.to_s + " " + page_units + " def"

# PostScript Template
ps_template = File.open(File.join(__dir__, "template.ps"), "r")
ps_template.each do |line|
    line = line.split("%")[0].lstrip.rstrip
    print line
    if line.length != 0 then print " " end
end
puts

# Current Block Type/Order
@cur_block_type = 0
@cur_block_order = 0

# Get Currently Applicable Content Style Setting
def get_style(key)

    # All Settings Specific to the Block Type
    styles_block = @stylesheet["content"][@cur_block_type.to_s]

    # Get the Setting we Want, and other things
    if (styles_block.is_a? Hash)
        style_block = styles_block[key]

        style_block_highest = styles_block[key + "_highest"]
        style_block_scale = styles_block[key + "_scale"]
        style_block_scale_limit = styles_block[key + "_scale_limit"]
        style_block_list = styles_block[key + "_list"]
        style_block_list_loop = styles_block[key + "_list_loop"]
    end

    # Global Default Setting
    style_default = @stylesheet["content"][key]

    offset = 0

    # Is there a setting for the highest order?
    if !style_block_highest.nil?
        offset += 1

        # If so, and we're on the highest order, use it
        if @cur_block_order == 0
            return style_block_highest

        # Otherwise, is there a scale and can we use it?
        elsif !style_block_scale.nil? && (style_block_highest.is_a? Numeric)

            # If so and there's no limit, use it
            unless (style_block_scale_limit.is_a? Integer)
                return style_block_highest * style_block_scale ** @cur_block_order

            # Otherwise, if we're within the limit, use it
            elsif @cur_block_order - offset < style_block_scale_limit
                return style_block_highest * style_block_scale ** @cur_block_order

            end
            offset += style_block_scale_limit

        end
    end

    # Is there a list of settings?
    if !style_block_list.nil?

        # If so and it's long enough, use the item at this order
        if @cur_block_order - offset < style_block_list.length
            return style_block_list[@cur_block_order - offset]

        # Otherwise, if it's supposed to loop, we can still use it
        elsif style_block_list_loop
            return style_block_list[(@cur_block_order - offset) % style_block_list.length]

        end
    end

    # If there's a setting specific to this block type at all, use it
    if !style_block.nil?
        return style_block
    end

    # Otherwise, just use the global default
    return style_default

end

# Fonts
@italic = false
@bold = false
@mono = false

# Get Font Name
def font_name()

    # If there is one font name, return it
    single_name = get_style("font_name")
    if !single_name.nil?
        name = single_name

    # Otherwise, get a font from the list
    else
        font_names = get_style("font_names")
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

# Indentation Levels
@indent_levels = [0]

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
        @list_item_prefix_font_name = font_name
        words.slice!(0)
        add_words(:list_item, indent_level, words)

    # Unordered List Item
    elsif words[0] == "-" || words[0] == "*" || words[0] == "+"
        end_block
        add_words(:list_item, indent_level, [])
        @list_item_prefix = next_list_item_prefix(false)
        @list_item_prefix_font_name = "/Symbol"
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

    # Whether this Prefix is a Symbol Character
    @list_item_prefix_symbol = !index

    # Ordered List Item Prefix
    if index
        case get_style("numeral")
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
        case get_style("bullet")
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
    set_parameters(get_style("font_size"), get_style("leading"), get_style("column_portions"))

    # Update Status Variables
    @prev_block_heading = @block_heading
    @block_heading = @cur_block_type == :heading

    # Vertical Spacing
    unless @first_block
        case get_style("space_above")
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
    case get_style("indent")
        when "always"
            indent = true
        when "not_after_heading"
            indent = !@prev_block_heading
    end

    # Justification/Alignment
    justify = false
    align = 0
    case get_style("align")
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
