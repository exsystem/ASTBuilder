{ Unit RBracketRule; }
Unit RBrkRule;

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
  Result := SymbRule.Parse(Lexer, ']');
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := eRBracket;
  Result.Parser := Parse;
End;

End.
