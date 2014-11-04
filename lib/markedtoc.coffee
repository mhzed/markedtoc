marked = require('./marked')

marked.pluginCompiler = require("./pluginCompiler");
marked.tocCompiler = require("./tocCompiler");
marked.ReactRenderer = require("./ReactRenderer");

# override lexer to do toc
do ->
  oldLexer = marked.lexer
  newLexer = (data, options)->
    toks = oldLexer(data, options)
    return marked.pluginCompiler(toks, {
      'TOC' : marked.tocCompiler
    })
  marked.Lexer.lex = newLexer
  marked.lexer = newLexer


module.exports = marked