Unit DoubleDotsRule;

{$I define.inc}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose(): TLexerRule;

Implementation

Uses
  KeywordRule;

Function Parse(Lexer: PLexer): Boolean;
Begin
  Result := KeywordRule.Parse(Lexer, '..');
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind.TokenKind := eDoubleDots;
  Result.TokenKind.TermRule := nil;
  Result.Parser := Parse;
End;

End.
