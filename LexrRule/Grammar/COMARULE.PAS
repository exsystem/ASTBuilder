Unit ComaRule;

{$I define.inc}

Interface

Uses
  Lexer, GLexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose: TLexerRule;

Implementation

Uses
  KywdRule;

Function Parse(Lexer: PLexer): Boolean;
Begin
  Result := KywdRule.Parse(Lexer, ',');
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := eComma;
  Result.Parser := Parse;
End;

End.
