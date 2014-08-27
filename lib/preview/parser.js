
/**
 * Module dependencies. 
 */
var md = require('../../index.js');

/**
 * Markdown parser with showdown.
 *
 * @param {String} input
 * @api public
 */
exports.parse = function(input) {
  return md(input);
};
  
