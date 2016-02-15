var fs = require('fs');
var dotmd = require('./index');

var stream = process.argv[2] ? fs.createReadStream(process.argv[2]) : process.stdin;

var datas = [];

stream.on('data', function(data) { return datas.push(data)});
stream.on('end', function() {
  var data = Buffer.concat(datas);
  console.log(dotmd(data.toString('utf8')));
});
