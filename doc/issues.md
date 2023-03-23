# NFA

Consider NFA with keywords:
- `'DO'`, `'DOWNTO'`, ...
- `':='`, `'>'`, ...
1. Order matters! `'DOWNTO'` should be before `'DO'` since they share common prefix `'DO'`.
2. Problem: How to convert if whitespaces should be ignored, such as `'DO'`, `'DOWNTO'`, ... versus `':='`, `'>'`, ... ?
   1. Solution (Possible): Use lookahead enabled parsing? (find the widest matched token)
   
# Lexer

Problem: Consider the lexer rule:
```
COMMENT : '{' .* '}' ->skip ;
```
How to scan all chars matching `.*` but stopped at the last `}` ?