
###
  tokens:  returned by marked lexer
  compilerMap:  {
    name : (param, iOffset, tokens) ->
      # param: parameter, embedded in markdown
      # iOffset: offset of plugin marker in tokens
      # tokens:  the original tokens returned by marked lexer
      # return compiled tokens
  }
  returns:  compiled tokens
###

module.exports = (tokens, compilerMap) ->

  compileToken = (token, i) ->
    if token.type == "paragraph"
      # [WORD.param]  where . is any non-word character,
      m = /^\[(\w+)(.*)\]$/i.exec(token.text)
      if (m)
        [all, name, param] = m
        if name of compilerMap then return compilerMap[name](param, i, tokens)
    return token

  compiledTokens = []
  for tok,i in tokens
    compiledTokens = compiledTokens.concat( compileToken(tok, i) )

  compiledTokens.links = tokens.links
  return compiledTokens
