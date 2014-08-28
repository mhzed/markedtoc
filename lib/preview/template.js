
/**
 * Module dependencies.
 */
var fs = require('fs')
  , clientjs = require('./client')
  , path = require("path");


/**
 * Render page with the given `map` object.
 *
 * @param {Object} map
 * @api public
 */
exports.render = function(map, theme, noJs) {
 
  var template = [
        '<!doctype html>'
      , '<html>'
      , '<head>'
      ,   '<meta charset="utf-8"/>'
      ,   '<title>{{ title }}</title>'
      ,   '<style>',
      ,   fs.readFileSync(path.resolve(__dirname, '../../theme/' + theme + '.css'), 'utf-8')
      ,   '</style>'
      , '</head>'
      , '<body>'
      ,   '{{ body }}'
      , '</body>'
      , '</html>'
  ].join('\n');       
          
  map && Object.keys(map).forEach(function(key){
    var reg = new RegExp("{{\\s*" + key + "\\s*}}", "g");
    template = template.replace(reg, map[key]);
  });

  return template + (noJs ? "" : clientjs);

};

