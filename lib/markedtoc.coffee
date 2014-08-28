marked = require('marked')

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
      type =  ordered ? 'ol' : 'ul'
      '<' + type + '>\n' + body + '</' + type + '>\n';
  marked.setOptions({
    renderer : renderer
  })

###
  tokens: returned by marked.Lexer.lex()
  returns:  iToc -> index of [TOC] paragraph, undefined if not found
            addSection -> [TOC.] detected, prefix heading with numeric section numbers
###
findToc = (tokens) ->

  testTOC = (token) ->
    if token.type == "paragraph"
      m = /^\[toc(.*)\]$/i.exec(token.text)
      if (m) then m[1]
      else undefined
    else undefined

  iToc = undefined
  addSection = true

  for tok,i in tokens
    tocParam = testTOC(tok)
    if (tocParam != undefined)
      iToc = i
      addSection = (tocParam == ".")
      break

  [iToc, addSection]

###
tokens: returned by marked.Lexer.lex()
returns:  tokens with [TOC] paragraph replaced and filled in with toc lists
###
replaceToc = (tokens)->

  [iToc, addSection] = findToc(tokens)
  if (iToc == undefined)
    return tokens;

  tocTokens = []
  root = [];
  rootLevel = 0;
  currentStack = root;
  currentLevel = rootLevel;
  for i in [iToc + 1 ... tokens.length ]
    token = tokens[i];
    if (token.type == "heading")
      if (token.depth > currentLevel)
        for k in [rootLevel ... token.depth-currentLevel]
          nextStack = []
          currentStack.push(nextStack);
          currentStack = nextStack;
        currentLevel = token.depth;
      else if ( currentLevel > token.depth )  # pop out of stack
        currentStack = root
        for k in [rootLevel ... token.depth]
          currentStack = currentStack[currentStack.length-1];
        currentLevel = token.depth;
      currentStack.push(token)
  # end for

  while (root.length == 1)
    root = root[0]

  # console.log(require("util").inspect(root, { showHidden: true, depth: 10 }));
  makeToc = (stack, toc, levelStacks) ->
    toc.push({
      type: 'list_start',
      ordered: 'toc'
    })

    x = 0
    while x < stack.length
      item = stack[x]
      if (item instanceof Array)
        makeToc(item, toc, levelStacks.concat(1));
      else
        tocId = levelStacks.join(".");
        label = item.text
        if addSection
          label = tocId + " " + label

        item.text = label
        # original marked.js line 793
        headingId = label.toLowerCase().replace(/[^\w]+/g, '-')

        toc.push({ type: 'list_item_start' });
        toc.push({
          type: 'text',
          text: "[" + label + "](#" + headingId + ")"
        })
        # include nested lists inside this item
        y = x+1
        while (y< stack.length && stack[y] instanceof Array)
          makeToc(stack[y], toc, levelStacks.concat(1));
          x++
          y++

        toc.push( { type: 'list_item_end' })
        levelStacks[levelStacks.length-1]++
        x++
      # end whiel
    toc.push( {type: 'list_end'} )
  # end makeToc

  makeToc(root, tocTokens, [1]);
  # replace [TOC] with a list of toc tokens
  tokens.splice.apply(tokens, [iToc, 1].concat(tocTokens));
  return tokens
