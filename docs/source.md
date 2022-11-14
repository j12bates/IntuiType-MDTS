# Source Files
Source files are essentially written in Markdown, but there are a few differences.

## Blocks
Source files are parsed into **blocks,** which are essentially the elements of a document.
Each block has a **level,** which is used for hierarchy and styling.
All blocks will end at the start of a new one or at a blank line.

### Paragraphs
Paragraphs are separated by blank lines or the start of a new block.
All paragraphs are level 1.

### Headings
Headings are denoted by a number of hash characters (`#`) at the start of the line.
They are only one line.
The number of hash characters used determines the heading level.
Headings can be level 1 through level 6.

```markdown
# Heading Level 1
## Heading Level 2
###### Heading Level 6
```

The alternate syntax using `=` or `-` characters below a line is not supported.

### Horizontal Rules
Horizontal rules are denoted by 3 or more hyphens (`---`) on a line by themselves.

```markdown
---
```

### Paragraphs with Special Indentation
Paragraphs with different types of indentation are denoted by a certain number of closing angle brackets (`>`) at the start of every line to be contained.
If a line is empty besides the angle brackets, it starts a new paragraph.

#### Blockquotes
Blockquotes are denoted by a single closing angle bracket (`>`).
All blockquotes are level 1, nested blockquotes are not supported.

```markdown
> Blockquotes are typically used for quotes or excerpts that are over
> four lines long
```

#### Hanging Indentation
Hanging indentation is denoted by two closing angle brackets (`>>`).

```markdown
>> Hanging indentation is usually used for citations and linking to
>> other resources
```

### List Items
The level of a list item is determined by the number of times the indentation level was advanced in previous lines,
and determines to the number of times an item will be indented.

```markdown
- level 1
  - level 2
      - level 3
    - level 3
 - level 2
- level 1
```

#### Ordered List Items
Ordered list items are denoted by a decimal integer (the index) followed by a period or full-stop (`.`) at the start of the first line.
Indices for the current level and any higher-level (lower number) list items are saved until a block that is not an ordered list item appears.
if there is a saved index, then it is incremented and used, otherwise the given index is used.

```markdown
1. First list item
2. Second list item
  6. Sixth higher-level list item
  1. Seventh higher-level list item (indices are saved)
5. Third list item
(indices are saved for lower levels)
```

#### Unordered List Items
Unordered list items are denotes by a hyphen (`-`), asterisk (`\*`), or plus-sign (`+`) at the start of the first line.

```markdown
- A list item
- Another list item
  - Yet another list item
  - Still another list item
- A list item again
```

### Code Blocks
Code Blocks are started and closed by a code fence, each made up of three backticks (```` ``` ````).
Any existing inline formatting settings are ignored within a code block, and they cannot be changed.
Any characters within code blocks are treated as literal characters, and serve no extended function.
All code blocks are level 1.

````markdown
```
#include <stdio.h>

int main()
{
    printf("Hello, world!\n")
}
```
````

## Inline Formatting
Inline formatting can be done with "delimiters".

An asterisk (`*`) or underscore (`_`) will enable emphasis (italic) when used at the beginning of a word (right of a space, newline, or other delimiter),
or end emphasis when used at the end of a word (left of a space, newline, or other delimiter).
Two asterisks (`**`) or underscores (`__`) will act similarly, but begin or end double-emphasis (bold).

Lastly, backticks (`` ` ``) will begin or end a code span (monotype).

```
ordinary *italic **bold-italic* `mono-bold`**
```

## Macros
Macros are a shorthand way to insert content configured elsewhere in the source file or provided by the stylesheet.
When a macro is called, it is rendered as though whatever content is assigned to it were in the same place.
A macro can create its own blocks or be used within a block.

Macros can be called by placing a bang (`!`) followed by the macro name (lowercase letters, numbers, and hyphens) at any place surrounded by spaces or newlines.

```
Name: !name-1
```

Since code blocks treat all characters as literal characters (including bangs), macros cannot be used within code blocks.

## Commands
Additional operations not supported by ordinary Markdown can be accomplished through the use of commands.

A command can be invoked by placing a backslach (`\\`) followed by the command name (lowercase letters) at the start of a line, followed by any arguments and a newline.
This will end the current block.

```
\command arg1 arg2
```

Since code blocks treat all characters as literal characters (including backslashes), commands cannot be used within code blocks.

### Local Macro Definition
Macros can be defined locally with the `def` command.
The first argument is the macro name (lowercase letters, numbers, and hyphens),
and any other arguments are interpreted as the content to assign to the macro.
Macros can be defined with the same name any number of times, but only the last definition is used.
Local macro definitions override any stylesheet definitions.

```
\def name-1 **Doe,** John
```

### Column/Page Breaks
A column break can be done with the `newcolumn` command.

A page break can be done with the `newpage` command.

### Escaping Characters
A literal character otherwise used for formatting can be input outside a code block by prefixing it with a backslash (`\\`).
Any of the following characters can be escaped:

```
\ ` * _ { } [ ] < > ( ) # + - . ! |
```
