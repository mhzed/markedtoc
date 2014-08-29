marked = require('marked')
pluginCompiler = require('./pluginCompiler')
tocCompiler = require('./tocCompiler')
module.exports = marked

# override lexer to do toc
do ->
  oldLexer = marked.lexer
  newLexer = (data, options)->
    toks = oldLexer(data, options)
    return replaceToc(toks)
  marked.Lexer.lex = newLexer
  marked.lexer = newLexer

# override renderer to set id toc for toc list
do ->
  renderer = new marked.Renderer();
  renderer.list = (body, ordered) ->
    if ordered=='toc'
      "<ul id='toc'>#{body}</ul>"
    else
      type =  if ordered then 'ol' else 'ul'
      '<' + type + '>\n' + body + '</' + type + '>\n';
  marked.setOptions({
    renderer : renderer
  })

###
tokens: returned by marked.Lexer.lex()
returns:  tokens with [TOC] paragraph replaced and filled in with toc lists
###
replaceToc = (tokens)->

  pluginCompiler(tokens, {
    'TOC' : tocCompiler
  })

