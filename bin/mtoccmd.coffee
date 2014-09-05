
o = require('optimist')
  .usage("""

Markdown to html generator with TOC support.
- Insert paragraph "[TOC]" in the markdown file to generate table of content in the html output.
- Insert paragraph "[TOC.]" in the markdown file to generate table of content with numbered section prefix.

Example:
  # print clean html to stdout
  mtoc file.md

  # preview in browser and save the up-to-date preview as file.md.html
  mtoc -s -v file.md
  """)
  .boolean("s")
  .boolean("v")
  .string('p')
  .string("css")
  .default('p', '3333')
  .describe('s', 'Save a copy of preview html file')
  .describe('v', 'Preview markdown as html in browser, in realtime')
  .describe("p", 'The port to listen on when in preview mode')
  .describe("css", "The optional url of css to use for html preview")
;

fs = require("fs")
marked = require("../lib/markedtoc")
path = require("path")
preview = require("../lib/preview")
mdFile = o.argv._[0]

if (o.argv._.length != 1)
  console.log o.help()
  process.exit 0

outFile = mdFile + ".html"

if o.argv.css
  preview.css = o.argv.css

if o.argv.v # preview
  preview.startServer(mdFile, parseInt(o.argv.p), outFile if o.argv.s)
else if o.argv.s
  preview.save(mdFile, outFile)
  console.log "Written to #{outFile}"
else
  console.log marked(fs.readFileSync(mdFile, 'utf-8'))

###