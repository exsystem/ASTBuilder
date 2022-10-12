Unit ShlRule;

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
  Result := KeywordRule.Parse(Lexer, 'Shl');
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eShl;
  Result.Parser := Parse;
End;

End.
