Unit EofRule;

{$I define.inc}

Interface

Uses
  Lexer, GLexer;

Function Parse(Lexer: PLexer): Boolean;

Function Compose: TLexerRule;

Implementation

Uses
  SymbRule;

Function Parse(Lexer: PLexer): Boolean;
Begin
  Result := SymbRule.Parse(Lexer, #0); { #0 }
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := eEof;
  Result.Parser := Parse;
End;

End.
