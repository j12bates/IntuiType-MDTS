# Stylesheets
Stylesheets are JSON files containing settings that determine details about how a document is rendered.
A stylesheet can be linked to a document when it is being compiled.

The root schema can contain two subschema: `content`, and the optional `page`.

## Page Settings
Page settings can be defined in the `page` schema.

### Page Size
Page size can be set using the property `size`.

To use a standard paper size, the value of can be defined as a string with one of the following values:
- `letter` (US letter paper, unit in)
- `a4` (A4 paper, unit mm)

For a custom paper size, the value can be defined as an object containing the following properties:
- `units` (string, `"in"` or `"mm"`)
- `width` (number)
- `height` (number)

If the value of the property is not defined properly, then it will default to `letter`.

The value of the property also determines the units of measure used by other page settings,
either through the preset page size or through the custom setting.

### Margin
Margin can be set using the property `margin`.

For the margin that is the same on all four sides, the value can be defined as a number.

Alternatively, for a margin that is constant vertically and constant horizontally,
the value can be defined as an object containing number properties `x` and `y`.

To set the margin on all four sides,
the value can be defined as an object containing number properties `left`, `right`, `top`, and `bottom`.

If the value of the property is not defined properly,
then it will default to `1` (in) or `25` (mm).

### Headers and Footers
Headers and footers are single lines of text within the top or bottom margin.
A header can be created using the property `header`, and a footer can be created with the property `footer`.
In addition, unique headers and footers for the first page can be made by using the properties `header-first` and `footer-first`.

The value must be defined as an object containing number properties `font_size` and `leading`.
It can also contain the object properties `left`, `center`, and/or `right`, which correspond to a mode of alignment.

Each of those alignment objects must contain the string property `font_name`.
They can also contain the string property `text`, which contains the actual text to be displayed,
or the string property `special`, which can be set to `"PAGE_NUMBER"`.

### Other
The length of an indent can be set by defining the property `indent` as a number.

The length of a gutter can be set by defining the property `gutter` as a number.

If the value of either of these properties are not defined properly,
then they will default to `0.5` (in) or `12.5` (mm).

## Content Settings
Settings pertaining to the rendering of content are defined as properties within the `content` schema.

### Block Types
Any setting can be made to apply only to a particular block type by defining it in a subschema.

The valid names for block type subschema are as follows:
- `paragraph`
- `heading`
- `block_quote`
- `list_item`
- `code_block`

### Levels
Any setting can be made to apply to certain block levels within a particular block type.

Additional properties of a block type subschema can be named with a setting's property name with one of the following suffixes:
- `_highest`
- `_scale`
- `_scale_limit`
- `_list`
- `_list_loop`

The `_highest` property can be defined as a setting value,
and when it is defined, it is applied to level 1 blocks.

If the `_highest` property is defined as a number and a `_scale` property is defined as a number,
then the setting for any remaining lower-level (higher number) blocks is calculated by scaling the `_highest` property by the `_scale` property N times,
where N is the difference in levels to 1.
Additionally, if the `_scale_limit` property is defined as integer N,
then only N levels past 1 will have the `_scale` property applied to them.

The `_list` property can be defined as a list of setting values,
and when it is defined, any remaining lower-level (higher number) blocks will use the settings,
with the highest-level applicable blocks which apply using the first item.
Additionally, if the `_list_loop` property is defined as the boolean `true`,
then the `_list` property settings will be extended to apply to all lower levels as though the list repeats.

### Fonts/Typefaces
A single font can be specified by defining the `font_name` property as a string containing the name of the font.
Be careful, this setting has higher precedence.

In order to support emphasis, double-emphasis, and code spans,
a typeface (or typefaces) can be specified by defining the `font_names` property as an eight-item array of strings containing font names in this order:
1. Ordinary
2. Italic
3. Bold
4. Bold Italic
5. Mono
6. Mono Italic
7. Mono Bold
8. Mono Bold Italic

At least one of these settings is required.

### Font Size and Leading
Font size can be set by defining the `font_size` property as a number equal to the desired point-size.

Leading can be set by defining the `leading` property as a number equal to the portion of the font size to be added.

Both of these settings are required.

### Columns
Content can be rendered in multiple columns by defining the `column_portions` property
as an array of numbers representing portions of the page to be allocated to a certain column.
For example, `[1]` keeps the content in one column,
and `[1, 2]` splits it into two columns where the right-hand column is twice as wide as the left-hand one.

This setting will default to `[1]`.

### Alignment/Justification
Paragraph alignment can be set by defining the `align` property as a string with one of the following values:
- `left` (default)
- `center`
- `right`
- `justify`

### Indentation/Paragraph Spacing
Indentation and paragraph spacing use these three string values:
- `always`
- `not_after_heading`
- `never` (default)

Indentation can be controlled by defining the `indent` property as one of the above values.

Paragraph spacing can be controlled by defining the `space_above` property as one of the above values.

### Bullets and Numbering
Bullets for unordered list items can be customized by defining the `bullet` property as one of the following string values:
- `bullet` (default)
- `star` OR `asterisk`
- `arrow`
- `arrow_double`

Numbering for ordered list items can be customized by defining the `numeral` property as one of the following string values:
- `arabic` (default)
- `alph_upcase`
- `alph_downcase`
