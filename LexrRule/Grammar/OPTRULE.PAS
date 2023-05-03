{ Unit OptionsRule; }
Unit OptRule;

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
  Result := KywdRule.Parse(Lexer, 'options');
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind.TokenKind := eOptions;
  Result.TokenKind.TermRule := nil;
  Result.Parser := Parse;
End;

End.
