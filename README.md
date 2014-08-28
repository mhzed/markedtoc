# markedtoc

Based on https://github.com/chjj/marked,  but add support for table of content, and real-time preview via 
browser.

Table of content is generated form the headings. 

# Usage

The library usage is exactly same as that of [marked](https://github.com/chjj/marked).

To use the TOC support, do the following:

- Insert paragraph "[TOC]" in the markdown file to generate table of content in the html output.
- Insert paragraph "[TOC.]" in the markdown file to generate table of content with numbered prefix.

# Command line

To generate clean html (without <html> tag and styles) to stdout:

    mtoc file.md

To preview file via styled html in browser in real time:

    mtoc -v file.md

To save a copy of preview html:
 
    mtoc -s file.md
    
    file.md.html will be created in the same directory as file.md.  Old file.md.xml is overwritten without
    warning!

To preview file in browser, and save a copy of preview html every time 'file.md' changes:

    mtoc -v -s file.md


