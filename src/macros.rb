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

class Macros

    # Macros
    @@macros = {}

    # Add Macro
    def Macros.add(key, string)
        unless key.match?(/^[a-z0-9-]+$/) || key == "_begin" || key == "_end" then return end
        @@macros[key] = string
    end

    # Get Macro
    def Macros.get(key)
        return @@macros[key]
    end

end
