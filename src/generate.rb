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

# Source File
source = File.open(ARGV[0], "r")

# Font Faces
@font_names = ["Times-Roman", "Times-Italic", "Times-Bold", "Times-Bold-Italic", "Courier", "Courier-Italic", "Courier-Bold", "Courier-Bold-Italic"]

@italic = false
@bold = false
@mono = false

def get_font()
    return @font_names[(@mono ? 4 : 0) + (@bold ? 2 : 0) + (@italic ? 1 : 0)]
end

def place_font_name()
    print "/" + get_font + " "
end

# Current Block Type
@block = 0

# Check First Word to see if we need to Start a New Block
def check_block(word)

    # Blockquote
    if word[0] == ">"
        if @block != :block_quote
            end_block
            @block = :block_quote
            place_font_name
        end

        return word[1, -1].to_s     # Remove the angle bracket

    # Paragraph
    else
        if @block != :paragraph
            end_block
            @block = :paragraph
            place_font_name
        end

        return word                 # Just use the word
    end

end

# End a Block
def end_block()
    case @block
        when :paragraph
            puts "PrintParagraph"
        when :block_quote
            puts "PrintBlockQuote"
    end

    @block = 0
end

# Begin Document
puts "Begin"

# Loop Through Lines
source.each do |line|
    words = line.split

    # Empty line means end of paragraph/whatever
    if words.length == 0
        end_block
        next
    end

    # Check if this is the same block
    words[0] = check_block(words[0])

    # Loop Through Words
    words.each do |word|

        # Format as a string, escape any special chars
        if word.length != 0
            word = word.gsub("\\", "\\\\")
            word = word.gsub("(", "\\(")
            word = word.gsub(")", "\\)")

            print "(" + word + ") "
        end

    end

end
end_block

# End Document
puts "End"
