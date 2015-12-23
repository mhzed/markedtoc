#
# Render markdown as xml spec, see https://github.com/expath/expath-cg/blob/master/tools/xmlspec/src/xmlspec.rnc
# The resulting xml should validate successfully by the schema defined above
# Following constraints apply:
# - There can only be two level 1 headings in the document, one denotes <body>, the other denotes <back>
# - All other headings must be levels >=2
# - <head> xml may follow the first level 1 headers, which is then inserted before <body>

marked = require('./../lib/marked')

escapeXml = (xml, encode)->
  rex = if !encode then /&(?!#?\w+;)/g else /&/g
  xml.replace(rex, '&amp;').\
    replace(/</g, '&lt;').\
    replace(/>/g, '&gt;').\
    replace(/"/g, '&quot;').\
    replace(/'/g, '&#39;');


class XmlspecRenderer extends marked.Renderer

  constructor : (options)->
    @sectionStack = []
    super(options)
    @options.xhtml = true
    @list_ordered = []

  enterToken : (token)->
    switch token.type
      when 'list_start' then @list_ordered.push token.ordered
      when 'list_end' then @list_ordered.pop()

  code : (code, lang, escaped)->
    if lang == "inline-md"
      "<eg>\n#{marked.inlineLexer(code,'.')}\n</eg>"
    else
      "<eg>\n#{if escaped then code else escapeXml(code)}\n</eg>"

  # marked pass in level 1 for #, 2 for ##, and so on
  # level 0 is reserved for <spec>
  # level 1 is reserved for <body> or <back>
  # leave 2 are for divs
  heading : (text, level, raw)->

    id = raw.toLowerCase().replace(/[^\w]+/g, '-')
    ret = ""
    # ensure spec section is started
    if @sectionStack.length == 0 then ret +=  @_nextHeading(0, "_spec", "_spec");

    if level == 1 and @sectionStack.length == 1 # on the first level 1 section, the article title, do nothing
      ret
    else
      if level >= 2 and @sectionStack.length == 1
        ret += @_nextHeading(1, "body", "body")  # lazy start of level 1 body section
      ret += @_nextHeading(level, text, id)
      ret

  _nextHeading : (level, text, id)->
    ret = ""

    # first close 'open' sections
    if @sectionStack.length > 0
      secs = ([lastLevel, lastId] for [lastLevel, lastId] in @sectionStack.slice(0).reverse()\
        when lastLevel >= level)  # find terminated sections

      if (secs.length >0 )
        # close headings with level >= 2
        ret = ("</div#{_level-1}>\n" for [_level] in secs when _level>1).join("")

        for [lastlevel, lastid] in (_sec for _sec in secs when _level<=1)
          if lastlevel == 1
            if lastid == "back"
              ret += "</back>"
            else
              ret += "</body>"
          else if lastlevel == 0
            ret += "</spec>"

        @sectionStack = @sectionStack[0...(- secs.length)]  # pop terminated sections

    # second save this section
    @sectionStack.push [level, id]

    # third construct open tags
    _html = do=>
      if level < 0 then ""
      else if level == 0 then "<spec>"
      else if level == 1
        if /^\s*back\s*$/i.test text then "<back>"  # back section
        else "<body>"
      else
        "<div#{level-1} id='#{id}'>\n<head>#{text}</head>\n"

    return ret + _html

  closeDoc : () ->
    return @_nextHeading(-1, "", "")

  list : (body, ordered)->
    if ordered
      "<olist>#{body}</olist>\n"
      #"<ol type='a'>#{body}</ol>\n"
    else
      "<ulist>#{body}</ulist>\n"

  listitem : (text)->
    if /^\s*</.test text
      "<item>#{text}</item>"
    else
      "<item><p>#{text}</p></item>"
    #if @list_ordered[-1..][0] then super(text)
    #else "<item>#{text}</item>"

  paragraph : (text)->
    super(text)

  html : (html)->
    super(html)

  blockquote : (quote)->
    "<quote>#{quote}</quote>"

  strong : (text)->
    "<rfc2119>#{text}</rfc2119>"  # xmlspec.rnc/xsl: the only tag that maps to <strong>

  em : (text)->
    "<emph>#{text}</emph>"

  link : (href, title, text)->
    "<loc href=\"#{href}\">#{text}</loc>"

#  hr : ()-> super()
#  table : (header, body)-> super(header, body)
#  tablerow : (content)-> super(content)
#  tablecell: (content)-> super(content)

#  codespan : (text)->
#  br : ()->
#  del : (text)->

#  image : (href, title, text)->

module.exports = XmlspecRenderer