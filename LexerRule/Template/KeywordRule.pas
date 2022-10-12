Unit KeywordRule;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer; Keyword: String): Boolean;

Implementation

Function Parse(Lexer: PLexer; Keyword: String): Boolean;
Begin
  Result := TLexer_PeekNextWord(Lexer, Keyword);
  If Result Then
  Begin
    Lexer.CurrentToken.Value := Keyword;
    Lexer.CurrentToken.StartPos := Lexer.NextPos;
    TLexer_Forward(Lexer, Length(Keyword));
  End;
End;

End.
