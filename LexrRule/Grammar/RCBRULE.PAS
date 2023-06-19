{ Unit RCurlyBracketRule; }
Unit RCBRule;

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
  Result := SymbRule.Parse(Lexer, '}');
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := eRCurlyBracket;
  Result.Parser := Parse;
End;

End.
