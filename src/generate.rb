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

# Stylesheet
require "json"

stylesheet_file = "default"

if ARGV.length >= 2
    stylesheet_file = ARGV[1]
end

@stylesheet = JSON.parse(File.read(File.join(__dir__, "res", stylesheet_file + ".json")))

# Fonts
@italic = false
@bold = false
@mono = false

# Get Font Name
def font_name()

    # List of Font Names
    font_names = @stylesheet["font_names"]

    # Heading
    if @cur_block_type == :heading && @stylesheet["heading"]["font_names"]
        font_names = @stylesheet["heading"]["font_names"]
    end

    # Get Name and Format as PostScript Name
    name = font_names[(@mono ? 4 : 0) + (@bold ? 2 : 0) + (@italic ? 1 : 0)]
    return "/" + name + " "
end

# Parameters
@font_size = 0
@leading = 0
@column_portions = []

# Update Font from Special Chars (Front or Back)
def update_font(word, front)

    font_changed = false

    # Check until we find a normal char
    i = front ? 0 : -1
    while word.length != 0
        case word[i]

            # Emphasis
            when "*"
                word.slice!(i)
                if word[i] == "*"
                    word.slice!(i)
                    @bold = !@bold
                else
                    @italic = !@italic
                end

            # Monospace
            when "`"
                word.slice!(i)
                @mono = !@mono

            # Normal char
            else
                break

        end

        font_changed = true
    end

    # Only return a font name if we should print it
    return font_changed ? font_name : ""

end

# Place a Word and any Font Changes
def place_word(word)

    # Escape Characters
    word = word.gsub("\\", "\\\\")
    word = word.gsub("(", "\\(")
    word = word.gsub(")", "\\)")

    # Font Changes
    cur_font = update_font(word, true)
    next_font = update_font(word, false)

    # Echo Word as String with any Font Names
    print cur_font + "(" + word + ") " + next_font

end

# Current Block Type
@cur_block_type = 0

# Heading Order
@heading_order = 0

# Add Words
def add_words(block_type, words)

    # Handle a New Block
    if block_type != @cur_block_type
        end_block
        @cur_block_type = block_type
        start_block
    end

    # Place Words as Strings
    words.each do |word|
        place_word(word)
    end

end

# Handle One Line
def handle_line(line)

    # Split into words
    words = line.split

    # Empty Line
    if words.length == 0
        end_block

    # Heading
    elsif words[0].count("#") == words[0].length && words[0].length >= 1 && words[0].length <= 6
        @heading_order = words[0].length - 1
        words.slice!(0)
        add_words(:heading, words)
        end_block

    # Blockquote
    elsif words[0] == ">"
        words.slice!(0)
        add_words(:block_quote, words)

    # Rule
    elsif words[0] == "---" && words.length == 1
        end_block
        puts "PrintRule"

    # Paragraph
    else
        add_words(:paragraph, words)

    end

end

# Start New Section
def new_section(new_column_portions)

    # Font Size and Leading
    print @font_size.to_s + " " + @leading.to_s + " "

    # Preserve Columns if Possible
    if new_column_portions == @column_portions
        print "0 "
    else

        # PostScript Array
        print "[ "
        for i in new_column_portions
            print i.to_s + " "
        end
        print "] "

    end

    # Keep Track of Columns
    @column_portions = new_column_portions

    # Procedure
    puts "NewSection "

end

# Start a Block
def start_block()

    # Deal with Parameters
    if @cur_block_type == :heading

        # Update Font Size if Necessary
        if @stylesheet["heading"]["font_size"] && @stylesheet["heading"]["font_size_order_scale"]
            @font_size = @stylesheet["heading"]["font_size"] * @stylesheet["heading"]["font_size_order_scale"] ** @heading_order
        else @font_size = @stylesheet["font_size"]
        end

        # Update Leading if Necessary
        if @stylesheet["heading"]["leading"]
            @leading = @stylesheet["heading"]["leading"]
        else @leading = @stylesheet["leading"]
        end

        # Update Columns if Necessary and Start New Section
        if @stylesheet["heading"]["column_portions"] && (@heading_order == 0 || @stylesheet["heading"]["column_order_persist"])
            new_section(@stylesheet["heading"]["column_portions"])
        else new_section(@stylesheet["column_portions"])
        end

    else

        # Update Parameters if Necessary
        if @font_size != @stylesheet["font_size"] || @leading != @stylesheet["leading"] || @column_portions != @stylesheet["column_portions"]

            # Start New Section
            @font_size = @stylesheet["font_size"]
            @leading = @stylesheet["leading"]
            new_section(@stylesheet["column_portions"])

        end

    end

    # Starting Font Name
    print font_name

end

# End a Block
def end_block()

    # Printing Procedure
    case @cur_block_type
        when :block_quote
            puts "PrintBlockQuote"
        when :heading
            puts "false " + (@stylesheet["heading"]["alignment"] == "center" && (@heading_order == 0 || @stylesheet["heading"]["alignment_order_persist"]) ? "1" : "0") + " PrintParagraphAligned"
        when :paragraph
            puts "PrintParagraph"
    end

    # Prevent this from Recurring
    @cur_block_type = 0

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
