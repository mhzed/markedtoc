
open   = require('open')
path   = require('path')
watch  = require('node-watch')
fs     = require('fs')
server = require('../lib/preview/server')
check  = require('../lib/preview/check')
stamp  = require('../lib/preview/stamp')

module.exports = {

  startServer: (filename, port, saveOnChangeFile) ->

    server.saveOnChangeFile = saveOnChangeFile
    server.css = module.exports.css

    check(filename)
    .accept(['md', 'markdown'])
    .pass((name)->
      watch(name, ()->
        stamp.update();
        console.log('%s changed.', name);
      )
      server.startAt(port, (res)->
        open('http://localhost:' + port + '/' + name)
        res && process.exit();
      )
    )
    .fail((name) ->
      if (name)
        console.log('Cannot open file %s.', name)
    )
  ,

  save: (inFile, outFile)->
    parser = require ("./preview/parser")
    template = require ("./preview/template")
    fs.writeFileSync(outFile, template.render({
      title: path.basename(inFile),
      body: parser.parse(fs.readFileSync(inFile, 'utf-8'))
    }, module.exports.css, true))

  # could be a full url
  css : 'default'
}