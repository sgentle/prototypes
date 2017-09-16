start
  = statement

statement
  = stmt:define "\n" statements:statement { return statements.concat([stmt]); }
  / stmt:define { return [stmt]; }

define
  = lvalue:identifier "=" expr:additive { return ['=', lvalue, expr]; }

additive
  = left:multiplicative "+" right:additive { return ['+', left, right]; }
  / multiplicative

multiplicative
  = left:primary "*" right:multiplicative { return ["*", left, right]; }
  / primary

primary
  = integer
  / "(" additive:additive ")" { return additive; }

integer "integer"
  = digits:[0-9]+ { return parseInt(digits.join(""), 10); }

identifier "identifier"
  = letters:[a-zA-Z][a-zA-Z0-9]* { return letters; }