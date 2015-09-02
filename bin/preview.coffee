
open   = require('open')
path   = require('path')
fs     = require('fs')
marked = require("./../lib/marked")
url    = require("url")
net     = require('net')
findport = require("find-free-port")
future   = require("phuture")
mime = require('mime-types')

module.exports = preview = {

  startServer: (filename, css, port, saveOnChangeFile) ->
    findport port, port + 100, '127.0.0.1', (err, port)->
      css ||= 'default'
      http = require('http');
      http.createServer((req, res)->
        if preview._exitFuture then preview._exitFuture.cancel()
        ourl = url.parse(req.url)

        mjp = /jsonp=([_\w\.]+)/.exec ourl.query

        if mjp  # jsonp poll
          f = mjp[1]
          preview._pushFuture = future.once 1000, (changed)->
            changed ?= false
            res.writeHead(200, {'Content-Type': 'text/javascript'});
            res.end "#{f}(#{changed})"
            preview._exitFuture = future.once 1000, ()-> console.log "Browser closed, exit."; process.exit(0)  # exit if no poll within 500ms

        else if ourl.pathname == "/"
          res.writeHead(200, {'Content-Type': 'text/html'});
          content = preview.render(filename, css)
          if saveOnChangeFile then fs.writeFileSync(saveOnChangeFile, content)
          res.end content
        else
          lfp = path.resolve(filename, ".."+ourl.pathname)
          if fs.existsSync(lfp)
            ctype = mime.lookup(path.extname(lfp)) || "applicaiton/octet-stream"
            res.writeHead(200, {'Content-Type': ctype});
            fs.createReadStream(lfp).pipe(res);
          else
            res.writeHead(404, {});
            res.end()


      ).listen(port, '127.0.0.1', ()->
        onChange = ()=>
          console.log "#{filename} changed"
          preview._pushFuture.finish(true)
          fs.watch filename, onChange

        fs.watch filename, onChange

        open("http://127.0.0.1:#{port}")
      ) # end listen

  _pushFuture : undefined
  _exitFuture : undefined

  # inFile : path to input markdown file
  # css: the css, could be url, or local path (embed style)
  render : (inFile, css)->
    if (/:\/\//.test(css))  # url
      style = '<link rel="stylesheet" type="text/css" href="' + css + '">';
    else if fs.existsSync(path.resolve(css))
      style = """
      <style>
      #{fs.readFileSync(path.resolve(css))}
      </style>
      """
    else
      style = """
      <style>
      #{require('../theme/default_css')}
      </style>
      """
    """
      <!doctype html>
      <html>
      <head>
        <meta charset="utf-8"/>
        <title>#{ path.basename(inFile) }</title>
        #{ style }
        <script>
          // JSONP-comet poll for reloading page, sever writes back jsonp(true|false), true: reload, false: no reload
          // poll interval is determined in server
          (window.mp = {
              _s : 0
            , init: function() {
                  document.addEventListener( "DOMContentLoaded", function() {
                    window.mp.injectScript('/?jsonp=mp.jsonpCallback');
                  });
                }
            , cleanScript : undefined
            , injectScript: function(src) {
                window.mp.cleanScript = undefined;
                src += "&_s=" + (window.mp._s++)
                var stag = document.createElement('script');
                stag.src = src;
                document.body.appendChild(stag);
                window.mp.cleanScript = function() {
                  stag.parentNode.removeChild(stag);
                }
              }
            , jsonpCallback: function(changed) {
                if (window.mp.cleanScript) window.mp.cleanScript();
                if (changed) window.location.reload();
                else window.mp.injectScript('/?jsonp=mp.jsonpCallback');
              }
          }).init();
        </script>
      </head>
      <body>
       #{ marked(fs.readFileSync(inFile, 'utf-8')) }
      </body>
      </html>
    """

  save: (inFile, css, outFile)->
    css ||= 'default'
    fs.writeFileSync(outFile, preview.render(inFile, css))

}
