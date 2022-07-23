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

# PostScript Template
ps_template = File.open(File.join(__dir__, "template.ps"), "r")
ps_template.each do |line|
    print line.split("%")[0].lstrip.rstrip + " "
end
puts

# Source File
source = File.open(ARGV[0], "r")

# Format Options
@font_name = "Times-Roman"

# Functions for Beginning/Ending Paragraphs
def paragraph_begin()
    puts "/" + @font_name + " "
end

def paragraph_end()
    puts "PrintParagraph"
end

# Begin Document
puts "Begin"

# Loop Through Lines
paragraph_begin()
source.each do |line|
    words = line.split

# Empty line means end of paragraph
    if words.length == 0
        paragraph_end()
        paragraph_begin()
        next
    end

# Loop Through Words
    words.each do |word|
        word = word.gsub("(", "\\(")
        word = word.gsub(")", "\\)")
        print "(" + word + ") "
    end

end
paragraph_end()

# End Document
puts "End"
