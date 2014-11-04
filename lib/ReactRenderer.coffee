###
  marked.setOptions({   # override default options
    renderer : new marked.ReactRenderer(marked.options.renderer)
  })
###

marked = require "./marked"

marked.ifHtmlEscape = false

module.exports = class ReactRenderer

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

  heading : (text, level, raw)->
    return @R['h' + level] (@_prop({
      children:text,
      id:@options.headerPrefix + raw.toLowerCase().replace(/[^\w]+/g, '-'),
    }));

  hr : () ->
    return @R.hr(@_prop());

  list : (body, ordered, id)->
    type = if ordered then 'ol' else 'ul';
    @R[type](@_prop({children:body, id}));

  listitem : (text)->
    return @R.li(@_prop({children:text}))

  paragraph : (text) ->
    return @R.p(@_prop(),text);

  table : (header, body) ->
    return @R.table(@_prop(),
        @R.thead(@_prop({children:header})),
        @R.tbody(@_prop({children:body}))
    );

  tablerow : (content)->
    return @R.tr(@_prop({children:content}))

  tablecell : (content, flags)->
    type = if flags.header then 'th' else 'td';
    props = @_prop({
      children:content
      style: {}
    })
    if flags.align
      props.style.textAlign = flags.align

    return @R[type](props);


  strong : (text)->
    return @R.strong( @_prop() ,text);

  em : (text) ->
    return @R.em( @_prop(),text);

  codespan : (text)->
    return @R.code( @_prop(), text);

  br : ()->
    return @R.br( @_prop() );

  del : (text)->
    return @R.del( @_prop(), text);

  link : (href, title, text) ->
    if (@options.sanitize)
      try
        prot = decodeURIComponent(unescape(href))
        .replace(/[^\w:]/g, '')
        .toLowerCase();
      catch e
        return @R.a( @_prop() );

      if (prot.indexOf('javascript:') == 0)
        return @R.a( @_prop() );

    return @R.a( @_prop({href:href,title:title}),text);

  image : (href, title, text)->
    return @R.img( @_prop({src:href,title:title,alt:text}));


