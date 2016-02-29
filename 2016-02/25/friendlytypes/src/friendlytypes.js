/* @flow */

function toflowtype(str: string, vars: ?Array<string>): string {
  vars = vars || ['a','b','c','d'];
  return gen(parse(lex(str)), vars);
};


function lex(str: string):Array<string> {
  return str.split(' ');
}

type AST = {type: string, children: Array<AST>, props: Object};

function addNode(node: AST, type: string) {
  const newNode = { type, children: [], props: {} };
  node.children.push(newNode);
  return newNode;
}

function holdsVars(type: string): boolean {
  return type == 'optional' ||
    type == 'decl' ||
    type == 'arguments' ||
    type == 'returns' ||
    type == 'subdecl';
}

function parse(tokens: Array<string>): AST {
  const root = {type: 'type', children: [], props: {}};
  var current = root;
  var path = [];

  tokens.forEach(token => {
    var newNode;
    // console.log("token", token, current.type);
    switch (token.toLowerCase()) {
      case 'a':
      case 'an':
        return;
      case 'that':
        return;
      case 'and':
        current = path.pop();
        return;
      case 'function':
        return;
      case 'takes':
        current = addNode(root, 'arguments');
        path.push(current);
        return;
      case 'of':
        current = addNode(current, 'subdecl');
        return;
      case 'returns':
        current = addNode(root, 'returns');
        path.push(current);
        return;
      case 'optional':
        current = addNode(current, 'optional');
        return;

      default:
        // console.log("current.type", current.type, "token", token, (current.type in ['optional', 'decl', 'arguments', 'returns']));
        if (!holdsVars(current.type)) current = path.pop();
        const child = { type: 'decl', children: [], props: {decl: token}};
        current.children.push(child);
        current = child;
    }
  });

  // console.log("AST", JSON.stringify(root, 0, 2));
  return root;
}

function gen(ast: AST, vars: Array<string>): string {
  switch (ast.type) {
    case 'type':
      var args = ast.children.find(x => x.type == 'arguments');
      var returns = ast.children.find(x => x.type == 'returns');
      return [arguments && gen(args, vars), returns && gen(returns, vars)].filter(Boolean).join(': ')
    case 'arguments':
      return '(' + ast.children.map(x => vars.shift() + ': ' + gen(x, vars)).join(', ') + ')';
    case 'returns':
      return gen(ast.children[0], vars);
    case 'optional':
      return '?' + gen(ast.children[0], vars);
    case 'decl':
      if (ast.children.length) {
        return `${ast.props.decl}<${ast.children[0].children.map(x => gen(x, vars)).join(',')}>`
      }
      return ast.props.decl;
    default:
      throw new Error("unknown ast type " + ast.type);
  }

}

module.exports = toflowtype;