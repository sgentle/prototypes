var funserver = require('./lib/funserver').default;
var fs = require('fs');

funserver(1234, function(request) {
  return Promise.resolve(fs.createReadStream('./test.js'));
});