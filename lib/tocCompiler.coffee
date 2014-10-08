
# The TableOfContent generator, as a plugin for pluginCompiler
module.exports = (param, iToc, tokens)->
  addSection = (param == ".")

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
  return tocTokens
