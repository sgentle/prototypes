var marked = require('marked');

module.exports = function(markdown) {
  var tokens = marked.lexer(markdown);

  return tokens.reduce(function(codetokens, token) {
    if (token.type === 'code') codetokens.push(token.text);
    return codetokens;
  }, []).join('\n');
};
