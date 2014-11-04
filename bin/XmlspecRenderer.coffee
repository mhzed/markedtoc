#
# Render markdown as ExPath spec, derived from http://w3.org/2002/xmlspec/xmlspec.rnc
# Following markdown file constraints apply:
# - There must exist one and ony one heading level 1 at the top of document
# - All other headings must be levels >=2
# - <head> xml may follow heading level 1
# - <back> xml may end document
#

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
    @bodyState = "none"   # none | begun | end
    super(options)
    @options.xhtml = true
    @list_ordered = []

  enterToken : (token)->
    switch token.type
      when 'list_start' then @list_ordered.push token.ordered
      when 'list_end' then @list_ordered.pop()

  code : (code, lang, escaped)->
    "<eg>\n#{if escaped then code else escapeXml(code)}\n</eg>"

  # level 1 => <spec>...
  # leave 2 => <div1>....
  _headingXml : (level, text, id)->
    if level == 1
      "<spec>"
    else
      ret = ""
      if @bodyState == "none"
        ret = "<body>"
        @bodyState = "begun"
      ret += "<div#{level-1} id='#{id}'><head>#{text}</head>"
      ret

  heading : (text, level, raw)->
    id = raw.toLowerCase().replace(/[^\w]+/g, '-')
    ret = @closeHeading(level, id)
    ret += @_headingXml(level, text, id)
    ret

  closeHeading : (nextLevel, nextId)->
    ret = ""
    if nextLevel == undefined then nextLevel = 0

    if @sectionStack.length > 0
      secs = ([lastLevel, lastId] for [lastLevel, lastId] in @sectionStack.slice(0).reverse()\
        when lastLevel >= nextLevel)  # find terminated sections
      if (secs.length >0 )
        ret = ("</div#{level-1}>" for [level] in secs[...-1]).join("")
        [lastlevel] = secs[secs.length-1]
        if lastlevel == 1
          ret += (if @bodyState == "end" then '</spec>' else '</body></spec>')
        else
          ret += "</div#{lastlevel-1}>"
        @sectionStack = @sectionStack[0...(- secs.length)]  # pop terminated sections

    if nextLevel then @sectionStack.push [nextLevel, nextId]
    return ret

  list : (body, ordered)->
    if ordered
      "<ol type='a'>#{body}</ol>"
    else
      "<ulist>#{body}</ulist>"

  listitem : (text)->
    if @list_ordered[-1..][0] then super(text)
    else "<item>#{text}</item>"

  paragraph : (text)->
    super(text)

  html : (html)->
    ret = ""
    if /<back>/.test(html)
      ret += @closeHeading(2, "back")
      ret += "</body>"
      @bodyState = "end"
      @sectionStack.pop()
    ret + super(html)

  blockquote : (quote)-> "<quote>#{quote}</quote>"

#  hr : ()-> super()
#  table : (header, body)-> super(header, body)
#  tablerow : (content)-> super(content)
#  tablecell: (content)-> super(content)
#  strong : (text)-> super(text)
#  em : (text)-> super(text)
#  codespan : (text)->
#  br : ()->
#  del : (text)->
#  link : (href, title, text)->
#  image : (href, title, text)->

module.exports = XmlspecRenderer