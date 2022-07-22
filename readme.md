# Intuitive Arrangement
A Lightweight Document Formatting Tool for Typesetting Documents from Largely Plaintext Source

---

## Installation
Install by copying the files in `src/` to a directory in `/opt/` or your preferred directory for installing software.

## Usage
```
install_dir/generate.rb INPUT_FILE
```
PostScript output is output to `stdout`. A PDF can be generated using `ps2pdf`.

## Input
Single line breaks are ignored. A double line break (creating a blank line) ends the current paragraph and starts a new one.
