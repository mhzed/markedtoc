o = require('optimist')
argv = o
  .usage("""

Markdown to html generator with TOC support.
- Insert paragraph "<TOC/>" in the markdown file to generate table of content in the html output.
- Insert paragraph "<TOC numbered/>" in the markdown file to generate table of content with numbered section prefix.

Example:
  # print clean html to stdout
  mtoc file.md

  # preview in browser and save the up-to-date preview as file.md.html
  mtoc -s -v file.md
  """)
  .boolean("s")
  .boolean("v")
  .boolean("x")
  .boolean("l")
  .string('p')
  .string("css")
  .default('p', '3333')
  .describe('s', 'Save a copy of preview html file')
  .describe('v', 'Preview markdown as html in browser, in realtime')
  .describe("p", 'The port to listen on when in preview mode')
  .describe("css", "The optional url of css to use for html preview")
  .describe("x", "output to stdout as xml spec")
  .describe("l", "output lexer output to stdout")
  .argv
;

fs = require("fs")
marked = require("../lib/markedtoc")
path = require("path")
preview = require("./preview")
mdFile = argv._[0]

if (argv._.length != 1)
  console.log o.help()
  process.exit 0

outFile = mdFile + ".html"

if argv.v # preview
  preview.startServer(mdFile, argv.css, parseInt(argv.p), outFile if argv.s)
else if argv.s
  preview.save(mdFile, argv.css, outFile)
  console.log "Written to #{outFile}"
else if argv.x
  # dump ExPath xmlspec
  XmlspecRenderer = require("./XmlspecRenderer")
  xmlSpecRender = new XmlspecRenderer()
  marked.setOptions({
    renderer : xmlSpecRender
  })
  output = marked(fs.readFileSync(mdFile, 'utf-8'))
  output += xmlSpecRender.closeHeading()

  beautifier = require("./vkbeautify")
  console.log beautifier.xml(output, 2)

else if argv.l
  console.log JSON.stringify(marked.lexer(fs.readFileSync(mdFile, 'utf-8')), null, 2)
else
  # dump html
  console.log marked(fs.readFileSync(mdFile, 'utf-8'))

###