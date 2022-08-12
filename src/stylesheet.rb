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

require "json"

class Stylesheet

    @@stylesheet = nil
    @@default = JSON.parse(File.read(File.join(__dir__, "res", "default.json")))

    def Stylesheet.load(file)
        if @@stylesheet.nil?
            @@stylesheet = JSON.parse(File.read(File.join(__dir__, "res", file + ".json")))
        end
    end

    # Get Page Setting
    def Stylesheet.get_page(key)
        return @@stylesheet["page"][key]
    end

    # Get Currently Applicable Content Style Setting
    def Stylesheet.get(block_type, block_order, key, specific)

        # All Settings Specific to the Block Type
        styles_block = @@stylesheet["content"][block_type.to_s]

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
        style_default = @@stylesheet["content"][key]

        offset = 0

        # Is there a setting for the highest order?
        if !style_block_highest.nil?
            offset += 1

            # If so, and we're on the highest order, use it
            if block_order == 0
                return style_block_highest

            # Otherwise, is there a scale and can we use it?
            elsif !style_block_scale.nil? && (style_block_highest.is_a? Numeric)

                # If so and there's no limit, use it
                if !(style_block_scale_limit.is_a? Integer)
                    return style_block_highest * style_block_scale ** block_order

                # Otherwise, if we're within the limit, use it
                elsif block_order - offset < style_block_scale_limit
                    return style_block_highest * style_block_scale ** block_order

                end
                offset += style_block_scale_limit

            end
        end

        # Is there a list of settings?
        if !style_block_list.nil?

            # If so and it's long enough, use the item at this order
            if block_order - offset < style_block_list.length
                return style_block_list[block_order - offset]

            # Otherwise, if it's supposed to loop, we can still use it
            elsif style_block_list_loop
                return style_block_list[(block_order - offset) % style_block_list.length]

            end
        end

        # If there's a setting specific to this block type at all, use it
        if !style_block.nil?
            return style_block
        end

        # If we can use the root setting, use it
        unless specific && style_default.nil?
            return style_default
        end

        # Otherwise, just use the program default
        return @@default["content"][key]

    end

end
