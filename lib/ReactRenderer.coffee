###
  marked.setOptions({   # override default options
    renderer : new marked.ReactRenderer(marked.options.renderer)
  })
###

marked = require "./marked"

module.exports = class ReactRenderer extends marked.Renderer

  # caller needs to supply React.DOM as @R, whose source maybe different depending on environment
  constructor: (@options, @R)->
    @lastline = -1
    @lastcur = 0

  getAppender : ()->
    return {
      _body  : []
      append : (toks)-> this._body = this._body.concat(toks)
      ret    : ()-> this._body
    };

  enterToken : (token)->
    if token.line != undefined and @lastline != token.line
      @lastline = token.line
      @lastcur = 0

  _prop : (p)->
    p ||= {}
    if @lastcur++ == 0
      p.key = @lastline
      p.ref = @lastline   # so that parent can find the descendant quickly
    else
      p.key = "#{@lastline}_#{@lastcur}"
    return p

  code : (code, lang, escaped)->
    if (@options.highlight)
      out = @options.highlight(code, lang);
      if (out != null && out != code)
        escaped = true;
        code = out;

    return @R.pre( @_prop(),
        @R.code(@_prop({
          className : if lang then @options.langPrefix + marked.escape(lang, true) else undefined
          dangerouslySetInnerHTML : {
            __html: if escaped then code else marked.escape(code, true)
          }
        }))
    )

  blockquote : (quote)->
    return @R.blockquote(@_prop({children:quote}));

  html : (html)->
    return @R.div(@_prop({dangerouslySetInnerHTML:{__html:html}}));

  heading : (inlineBody, level, raw)->
    return @R['h' + level] (@_prop({
      dangerouslySetInnerHTML:{__html:inlineBody}
      id:@options.headerPrefix + raw.toLowerCase().replace(/[^\w]+/g, '-'),
    }));

  list : (items, ordered, id)->
    type = if ordered then 'ol' else 'ul';
    return @R[type](@_prop({
      children: items
      id
    }));

  listitem : (body)->
    # React wraps text inside <span>, to avoid it, we preempt by wrap in div first
    for e,i in body when typeof e == 'string'
      body[i] = @R.div {dangerouslySetInnerHTML:{__html:e}}
    return @R.li(@_prop({
      children: body
    }))

  paragraph : (inlineBody) ->
    return @R.p(@_prop({
      dangerouslySetInnerHTML:{__html:inlineBody}
    }));

  table : (header, rows) ->
    return @R.table(@_prop(),
        @R.thead(@_prop({children: header})),
        @R.tbody(@_prop({children: rows}))
    );

  tablecell : (inlineBody, flags)->
    type = if flags.header then 'th' else 'td';
    props = @_prop({
      dangerouslySetInnerHTML:{__html:inlineBody}
      style: {}
    })
    if flags.align
      props.style.textAlign = flags.align

    return @R[type](props);

  tablerow : (cells)->
    return @R.tr(@_prop({children:cells}))

  hr : () ->
    return @R.hr(@_prop());

  ### inline render, leave default implementation
  strong : (text)->
    return '<strong>' + text + '</strong>';
  em : (text) ->
    return '<em>' + text + '</em>';
  codespan : (text)->
    return '<code>' + text + '</code>';
  br : ()->
    return '<br/>'
  del : (text)->
    return '<del>' + text + '</del>';
  link : (href, title, text) ->
  image : (href, title, text)->
  ###

