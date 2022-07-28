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

# Font Faces
@font_names = @stylesheet["font_names"]

@italic = false
@bold = false
@mono = false

# Get Font Name
def font_name()
    name = @font_names[(@mono ? 4 : 0) + (@bold ? 2 : 0) + (@italic ? 1 : 0)]
    return "/" + name + " "
end

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

# Add Words
def add_words(block_type, words)

    # Handle a New Block
    if block_type != @cur_block_type
        end_block
        @cur_block_type = block_type
        print font_name
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

# End a Block
def end_block()

    # Printing Procedure
    case @cur_block_type
        when :paragraph
            puts "PrintParagraph"
        when :block_quote
            puts "PrintBlockQuote"
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
