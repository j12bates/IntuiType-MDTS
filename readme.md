# IntuiType -- Markdown Typesetter
For those who just want to write nicely formatted documents without breaking out a word processor or dealing with LaTeX or t/groff.
Produces consistent results without much overhead or customization: just use some basic markdown if you want to do additional formatting.

---

## Source Files
A source file contains all the text to be included in the document.
It it written using many of the conventions used by markdown, with some differences.
Information on how they are structured and parsed and what features are supported can be found in `docs/source.md`.
An example source incorporating supported features can be found in `example.md`.

## Stylesheets
Stylesheets are used to format all elements of a document while it is being generated.
They are JSON files located in `src/res/`.
Information on how they are interpreted can be found in `docs/stylesheets.md`.

## Installation
Install by copying the files in `src/` to a directory in `/opt/` or your preferred directory for installing software.
Ensure that `generate.rb` is executable.

```
mkdir install_dir
chmod +x src/generate.rb
cp -r src/ install_dir/
```

## Usage
```
install_dir/generate.rb SOURCE_FILE [STYLESHEET]
```
PostScript output is put to `stdout`.
A PDF can be generated using `ps2pdf`.

If no stylesheet is specified when generating a document, `default` is used.
