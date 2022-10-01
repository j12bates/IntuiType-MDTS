#
#     Copyright 2022 Jacob Bates
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
#


require_relative "stylesheet.rb"
require_relative "macros.rb"

class PageSetup

# Set Up All Document Standards
    def PageSetup.standards()

        page_units = "in"

        # ================ PAGE SIZE ================

        page_size = Stylesheet.get_page("size")
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
        puts "<< /PageSize [ PageWidth PageHeight ] >> setpagedevice"

        # Standard Length (used in default margin, indent, and gutter)
        case page_units
            when "in"
                page_default = 1.0
            when "mm"
                page_default = 25.0
        end

        # ================ MARGIN ===============

        page_margin = Stylesheet.get_page("margin")
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

        # ================ INDENT AND GUTTER ===============

        standard_indent = Stylesheet.get_page("indent")
        standard_gutter = Stylesheet.get_page("gutter")

        unless (standard_indent.is_a? Numeric) then standard_indent = page_default / 2 end
        unless (standard_gutter.is_a? Numeric) then standard_gutter = page_default / 2 end

        puts "/Indent " + standard_indent.to_s + " " + page_units + " def"
        puts "/Gutter " + standard_gutter.to_s + " " + page_units + " def"

    end

# Set Up Header and Footer
    def PageSetup.header_footer()

        # Both Header and Footer
        ["header", "footer"].each do |header_footer|

            # First Page and Subsequent Pages
            [true, false].each do |first|

                # Properties
                settings = Stylesheet.get_page(header_footer + (first ? "_first" : ""))

                # Check Required Properties
                unless settings.is_a? Hash then settings = {} end
                unless settings["font_size"].is_a? Numeric then settings["font_size"] = 0 end
                unless settings["leading"].is_a? Numeric then settings["leading"] = 0 end

                # If there isn't something specific to the first page, use this on the first page
                first = first || Stylesheet.get_page(header_footer + "_first").nil?

                # Each Side
                ["left", "center", "right"].each do |side|

                    items = ""

                    # Check Required Properties
                    unless settings[side].is_a? Hash then settings[side] = {} end

                    # Font Name
                    if settings[side]["font_name"].is_a? String
                        items += "/" + settings[side]["font_name"] + " "

                    # If no font name, do nothing else
                    else settings[side] = {} end

                    # Plain Text
                    if (settings[side]["text"].is_a? String)
                        items += PageSetup.place_words(settings[side]["text"])
                    end

                    # Page Number
                    if settings[side]["page_number"]
                        items += "documentPage (    ) cvs "
                    end

                    # Define Side Procedure
                    print "/" + (first ? "" : "Next") + header_footer.capitalize + side.capitalize + " { " + items + "} def "

                end

                # Define Size and Leading
                print "/" + (first ? "" : "Next") + header_footer.capitalize + "FontHeight " + settings["font_size"].to_s + " def "
                print "/" + (first ? "" : "Next") + header_footer.capitalize + "Leading " + settings["leading"].to_s + " def "
                puts

            end

        end

    end

# Place Words
    private
    def PageSetup.place_words(string)

        items = ""

        if string.nil? then return "" end

        # Split into Words
        string.split.each do |word|

            # Expand Macro
            if word.match?(/^![a-z0-9-]+$/)
                items += PageSetup.place_words(Macros.get(word[1..-1]))

            # Place Words
            else

                # Escape Characters
                word = word.gsub("\\", "\\\\\\\\")
                word = word.gsub("(", "\\(")
                word = word.gsub(")", "\\)")

                # Append Word
                items += "(" + word + ") "

            end

        end

        return items

    end

end
