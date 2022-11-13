# IntuiType -- Markdown Typesetter
For those who just want to write nicely formatted documents without breaking out a word processor or dealing with LaTeX or t/groff.
Produces consistent results without much overhead or customization: just use some basic markdown if you want to do additional formatting.

---

## Installation
Install by simply running `make install` as root, with `$PREFIX` set appropriately if desired.

## Usage
```sh
intuitype SOURCE DEST [STYLESHEET]
```

The source is the filename of an input markdown file, and the destination is the filename for an output PDF file.
If no stylesheet is specified, `default` is used.

## Source Files
A source file contains all the text to be included in the document.
It it written using many of the conventions used by markdown, with some differences.
Information on how they are structured and parsed and what features are supported can be found in `docs/source.md`.
An example source incorporating supported features can be found in `example.md`.

## Stylesheets
Stylesheets are used to format all elements of a document while it is being generated.
They are JSON files located in `src/res/`.
Information on how they are interpreted can be found in `docs/stylesheets.md`.

Stylesheets available:
- `default`
- `article-onecolumn`
- `article-twocolumn`
- `memorandum`
- `mla`
