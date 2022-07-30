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

# TODO - Implement Alignment as a Style Setting
# TODO - Raise Exceptions when Style Settings are Missing

# TODO - Add Page Size and Document Standards to Stylesheet/Something else
# TODO - Anchors (actually just URIs with an icon ig)
# TODO - Headers, Footers, Page Numbers
# TODO - Stylesheets Can Add Things to Document and Prompt for Custom Content (e.g. memo to/from/subject)

# PostScript Version
puts "%!PS-Adobe-3.0"

# Notice
puts
puts "% This PostScript document was produced using the IntuiType Markdown Typesetter."
puts "% To convert to a PDF, run"
puts "%     ps2pdf FILENAME.ps FILENAME.pdf"
puts "% Direct PDF output has not yet been implemented."
puts

# Page Size
paper_size = "letter"
puts "/PaperSize /" + paper_size + " def"

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

# Stylesheet
require "json"

stylesheet_file = "default"

if ARGV.length >= 2
    stylesheet_file = ARGV[1]
end

@stylesheet = JSON.parse(File.read(File.join(__dir__, "res", stylesheet_file + ".json")))

# Get Currently Applicable Style Setting
def get_style(key)

    # All Settings Specific to the Block Type
    styles_block = @stylesheet[@cur_block_type.to_s]

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
    style_default = @stylesheet[key]

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
            if style_block_scale_limit.nil?
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

            # Escaped Character
            when "\\"
                pos += left ? 2 : -2

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

# List Index
@list_indices = []
@given_list_index = 0
@list_index_font_name = ""

# Indentation Levels
@indent_levels = [0]

# Don't add space to the first block
@start_paragraph_space = false

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
        puts "false 0 PrintParagraphAligned"

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
        add_words(:block_quote, 0, words)

    # Ordered List Item
    elsif words[0][-1] == "." && (Integer(words[0][0..-2]) rescue false)
        end_block
        words[0].slice!(-1)
        @given_list_index = Integer(words[0]) rescue false
        words.slice!(0)
        @list_index_font_name = font_name
        add_words(:ordered_list_item, indent_level, words)

    # Unordered List Item
    elsif words[0] == "-" || words[0] == "*" || words[0] == "+"
        end_block
        words.slice!(0)
        add_words(:unordered_list_item, indent_level, words)

    # Horizontal Rule
    elsif words[0].count("-") == words[0].length && words[0].length >= 3 && words.length == 1
        end_block
        puts "PrintRule"
        @start_paragraph_space = false

    # Handle Continuing List Item
    elsif @cur_block_type == :ordered_list_item || @cur_block_type == :unordered_list_item
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

# Start a Block
def start_block()

    # Update Parameters
    set_parameters(get_style("font_size"), get_style("leading"), get_style("column_portions"))

    # Paragraph Space if Needed
    if get_style("paragraph_space") && @start_paragraph_space
        print "NextLine "
    end

    # The next block can be spaced, unless this is a heading
    @start_paragraph_space = @cur_block_type != :heading

    # Deal with List Index
    if @cur_block_type == :ordered_list_item

        # Get rid of any lower-order list indices
        @list_indices = @list_indices[0..@cur_block_order]

        # If the list is continuing, increment the index
        if @list_indices[@cur_block_order]
            @list_indices[@cur_block_order] += 1

        # Otherwise, use the index given
        else
            @list_indices[@cur_block_order] = @given_list_index
        end

    # If the list has ended, don't keep track of the index or order
    elsif @cur_block_type != :unordered_list_item
        @list_indices = []
    end

    # Starting Font Name
    if @cur_block_type != :code_block
        print font_name
    end

end

# End a Block
def end_block()

    # Printing Procedure
    case @cur_block_type
        when :block_quote
            puts "PrintBlockQuote"
        when :heading
            puts "false " + (get_style("alignment") == "center" ? "1" : "0") + " PrintParagraphAligned"
        when :ordered_list_item
            puts @list_index_font_name + "(" + @list_indices[@cur_block_order].to_s + ") " + @cur_block_order.to_s + " PrintOrderedListItem"
        when :unordered_list_item
            puts @cur_block_order.to_s + " PrintBulletListItem"
        when :paragraph
            puts "PrintParagraph"
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
