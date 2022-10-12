Unit GERule;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

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
  Result := KeywordRule.Parse(Lexer, '>=');
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eGE;
  Result.Parser := Parse;
End;

End.
