Unit ShlRule;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose(Lexer: PLexer): TLexerRule;

Implementation

Uses
  KeywordRule;

Function Parse(Lexer: PLexer): Boolean;
Begin
  Result := KeywordRule.Parse(Lexer, 'Shl');
End;

Function Compose(Lexer: PLexer): TLexerRule;
Begin
  Result := KeywordRule.Compose(Lexer, Parse, eShl, 'Shl');
End;

End.
