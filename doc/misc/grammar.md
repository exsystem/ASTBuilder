# Original EBNF

```
expr -> id
  | id
  | term
  | '(' expr ')'
  | expr '?'
  | expr '*'
  | expr '|' expr
  | expr expr

rule -> id ':' expr ';'

grammar -> rule*
```

# Equvalent Conversion With Out Left-Recursion

```
factor -> id '?' | id '*' | id
  | term '?' | term '*' | term
  | '(' expr ')' '?' | '(' expr ')' '*' | '(' expr ')'

expr -> factor factor* ( '|' factor factor* )*

rule -> id ':' expr ';'

grammar -> rule*
```

# Example DFA

## Rule
 ```
 e -> f f* ( '|' f f* )*
 ```

## DFA

```mermaid
graph LR
  S1((S1))--f-->S2
  S2(S2)--f-->S2
  S2--"|"-->S3
  S3((S3))--f-->S4
  S4(S4)--"|"-->S3
  S4--f-->S4
```
> Begin with State Node S1. State Node S2 and S4 are final states. SEE: `ExprRuleExpression1()` in `PruductionRule/ExprRuleUnit.pas`