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

### Blockquotes
Blockquotes are denoted by a closing angle bracket (`>`) at the start of every line to be contained.
If a line is empty besides the angle bracket, it starts a new blockquote.
All blockquotes are level 1, nested blockquotes are not supported.

```markdown
> Blockquotes can be split up into
> multiple lines, like paragraphs
>
> This will be a separate block
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
Macros are a shorthand way to insert content provided by the stylesheet.
This content can be made up of any blocks.
When a macro is invoked, it causes the current block to end,
and after the macro ends, a new block may begin.

They can be denoted by a backslash (`\\`) followed by the macro name (lowercase letters, numbers, and hyphens) on a line.

```
\lorem-ipsum
```
