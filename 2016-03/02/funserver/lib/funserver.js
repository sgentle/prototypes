'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _http = require('http');

var _http2 = _interopRequireDefault(_http);

var _stream = require('stream');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

//ugh

var friendlyFunserver = function friendlyFunserver() {
  return arguments.length == 3 ? funserver(arguments.length <= 0 ? undefined : arguments[0], arguments.length <= 1 ? undefined : arguments[1], arguments.length <= 2 ? undefined : arguments[2]) : funserver('localhost', arguments.length <= 0 ? undefined : arguments[0], arguments.length <= 1 ? undefined : arguments[1]);
};

var funserver = function funserver(host, port, fun) {
  var server = _http2.default.createServer(function (request, response) {
    return fun(Promise.resolve(request)).then(function (result) {
      return result.pipe(response);
    }).catch(function (err) {
      response.statusCode = 500;
      response.end(err.toString());
    });
  });
  server.listen(port);

  console.log("host", host, "port", port, "fun", fun);
};

exports.default = friendlyFunserver;