Unit SkipRule;

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
  Result := KeywordRule.Parse(Lexer, '->skip');
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind.TokenKind := eSkip;
  Result.TokenKind.TermRule := nil;
  Result.Parser := Parse;
End;

End.
