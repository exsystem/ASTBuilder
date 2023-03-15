Unit DotRule;

{$I define.inc}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose: TLexerRule;

Implementation

Uses
  KywdRule;

Function Parse(Lexer: PLexer): Boolean;
Begin
  Result := KywdRule.Parse(Lexer, '.');
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind.TokenKind := eDot;
  Result.TokenKind.TermRule := nil;
  Result.Parser := Parse;
End;

End.
