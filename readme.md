# Intuitive Arrangement
A Lightweight Document Formatting Tool for Typesetting Documents from Largely Plaintext Source

---

## Source Files
A source file contains all the text to be included in the document.
Single line breaks are ignored. A double line break (creating a blank line) ends the current paragraph and starts a new one.
An example source incorporating most features can be found in `example.txt`.

## Installation
Install by copying the files in `src/` to a directory in `/opt/` or your preferred directory for installing software.
Ensure that `generate.rb` is executable.
```
mkdir install_dir
chmod +x src/generate.rb
cp src/* install_dir/
```

## Usage
```
install_dir/generate.rb SOURCE_FILE
```
PostScript output is put to `stdout`.
A PDF can be generated using `ps2pdf`.
