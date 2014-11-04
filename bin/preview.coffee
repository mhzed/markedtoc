
open   = require('open')
path   = require('path')
fs     = require('fs')
marked = require("./../lib/marked")
url    = require("url")
net     = require('net')
findport = require("find-free-port")
future   = require("phuture")


module.exports = preview = {

  startServer: (filename, css, port, saveOnChangeFile) ->
    findport port, port + 100, '127.0.0.1', (err, port)->
      css ||= 'default'
      http = require('http');
      http.createServer((req, res)->
        if preview._exitFuture then preview._exitFuture.cancel()
        query = url.parse(req.url).query
        mjp = /jsonp=([_\w\.]+)/.exec query
        if mjp
          preview._pusher = {req, res, f: mjp[1], ts: Date.now()}
          preview._pollFuture = future.once 1000, ()->preview.push(false)  # poll return after 1 sec
        else
          res.writeHead(200, {'Content-Type': 'text/html'});
          content = preview.render(filename, css)
          if saveOnChangeFile then fs.writeFileSync(saveOnChangeFile, content)
          res.end content
      ).listen(port, '127.0.0.1', ()->

        onChange = ()=>
          console.log "#{filename} changed"
          preview.push(true)  # poll reply immediately
          fs.watch filename, onChange
        fs.watch filename, onChange

        open("http://127.0.0.1:#{port}")
      ) # end listen

  _pusher    : undefined
  _pollFuture : undefined
  _exitFuture : undefined

  push : (changed)->  # tell browser if file changed or not
    if preview._pusher
      {req, res, f, ts} = preview._pusher
      res.writeHead(200, {'Content-Type': 'text/javascript'});
      res.end "#{f}(#{changed})"
      preview._pusher = null
      preview._exitFuture = future.once 500, ()-> console.log "Browser closed, exit."; process.exit(0)  # exit if no poll within 500ms
      preview._pollFuture.cancel()


# inFile : path to input markdown file
  # css: the css, could be url, or local path (embed style)
  render : (inFile, css)->
    if (/:\/\//.test(css))  # url
      style = '<link rel="stylesheet" type="text/css" href="' + css + '">';
    else
      style = """
      <style>
      #{fs.readFileSync(path.resolve(__dirname, '../theme/' + css + '.css'), 'utf-8')}
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
