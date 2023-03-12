{ Unit RBracketRule; }
Unit RBrkRule;

{$I define.inc}

Interface

Uses
  Lexer;

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
  Result.TokenKind.TokenKind := eRBracket;
  Result.TokenKind.TermRule := nil;
  Result.Parser := Parse;
End;

End.