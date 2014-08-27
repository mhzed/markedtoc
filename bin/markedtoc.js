#!/usr/bin/env node
require("..");  // polyfill marked first
var path = require("path");

var bin = path.join(require.resolve("marked"), "../../bin/marked");
require(bin)(process.argv.slice(), function(err, code) {
  if (err) throw err;
  return process.exit(code || 0);
});