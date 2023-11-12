Unit PPMDRULE;

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
  Result := KywdRule.Parse(Lexer, 'popMode');
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := ePopMode;
  Result.Parser := Parse;
End;

End.
