Unit SymbolRule;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer; Const Ch: Char): Boolean;

Implementation

Function Parse(Lexer: PLexer; Const Ch: Char): Boolean;
Begin
  Result := (TLexer_PeekNextChar(Lexer) = Ch);
  If Result Then
  Begin
    Lexer.CurrentToken.Value := TLexer_PeekNextChar(Lexer);
    Lexer.CurrentToken.StartPos := Lexer.NextPos;
    TLexer_Forward(Lexer);
  End;
End;

End.
