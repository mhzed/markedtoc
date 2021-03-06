# markedtoc

Based on https://github.com/chjj/marked,  but add support for table of content, and real-time preview via 
browser.

Table of content is generated from the headings that follow the TOC marker.  See 
[README.md.html](http://htmlpreview.github.io/?https://github.com/mhzed/markedtoc/blob/master/README.md.html) 
for example.
 
<TOC numbered/>

# Installation

Install [nodejs](http://nodejs.org)

Then run command:

    npm install -g markedtoc

# Usage

The library usage is exactly the same as that of [marked](https://github.com/chjj/marked).

To use the TOC support, do the following:

- Insert &lt;TOC/> in the markdown file to generate table of content in the html output.
- Insert &lt;TOC numbered/> in the markdown file to generate table of content with numbered prefix.


## Command line

To generate clean html to stdout:

    mtoc README.md

To live preview file via default styled html in browser in real time:

    mtoc -v README.md

To save a copy of preview html:
 
    mtoc -s README.md
    
    README.md.html will be created in the same directory as README.md.  Old README.md.xml is overwritten without
    warning!

To preview file in browser, and save a copy of preview html every time 'README.md' changes:

    mtoc -v -s README.md

To preview in browser using W3C working-draft style:

    mtoc -v README.md --css http://www.w3.org/StyleSheets/TR/W3C-WD.css
    
