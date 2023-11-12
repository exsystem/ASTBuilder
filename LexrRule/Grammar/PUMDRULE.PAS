Unit PUMDRULE;

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
  Result := KywdRule.Parse(Lexer, 'pushMode');
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := ePushMode;
  Result.Parser := Parse;
End;

End.
