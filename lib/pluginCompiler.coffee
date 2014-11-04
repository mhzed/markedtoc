
###
  tokens:  returned by marked lexer
  compilerMap:  {
    name : (param, iOffset, tokens) ->
      # name: name of tag, or element name
      # param: parsed xml attributes stored as object
      # iOffset: offset of plugin marker in tokens
      # tokens:  the original tokens returned by marked lexer
      # return compiled tokens
  }
  returns:  compiled tokens
###
parseXmlAttr = (str)->
  o = {}
  o[m[1]] = m[2] for t in str.split(/\s+/) when (m = /^([a-zA-Z_:][-a-zA-Z0-9_:.]*)\s*=?\s*['"]?(.*?)['"]?\s*$/.exec(t))
  o

module.exports = (tokens, compilerMap) ->

  compileToken = (token, i) ->
    if token.type == "html"
      m = /^<(\w+)(.*?)\/?>/.exec(token.text)
      if (m)
        [all, tag, param] = m
        param = parseXmlAttr(param)
        if tag of compilerMap then return compilerMap[tag](param, i, tokens)
    return token

  compiledTokens = []
  for tok,i in tokens
    compiledTokens = compiledTokens.concat( compileToken(tok, i) )

  compiledTokens.links = tokens.links
  return compiledTokens

