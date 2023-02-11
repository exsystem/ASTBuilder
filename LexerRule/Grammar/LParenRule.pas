Unit LParenRule;

{$I define.inc}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose(): TLexerRule;

Implementation

Uses
  SymbolRule;

Function Parse(Lexer: PLexer): Boolean;
Begin
  Result := SymbolRule.Parse(Lexer, '(');
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind.TokenKind := eLParen;
  Result.TokenKind.TermRule := nil;
  Result.Parser := Parse;
End;

End.
