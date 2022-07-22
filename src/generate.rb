#!/usr/bin/ruby

# PostScript Template
ps_template = File.open(File.join(__dir__, "template.ps"), "r")
puts ps_template.read

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
