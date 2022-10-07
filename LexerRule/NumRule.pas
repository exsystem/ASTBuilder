Unit NumRule;

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
  StringUtils;

Function Parse(Lexer: PLexer): Boolean;
Begin
  If IsDigit(Lexer.CurrentChar) Then
  Begin
    // look self...
    Lexer.CurrentToken.StartPos := Lexer.CurrentPos;
    While IsDigit(TLexer_PeekNextChar(Lexer)) Do
    Begin
      TLexer_MoveNextChar(Lexer);
    End;
    // look after...
    If Not (TLexer_PeekNextChar(Lexer) In [' ', '+', '-', '*', '/', ')', #0]) Then
    Begin
      Lexer.CurrentToken.Kind := eUndefined;
      TLexer_MoveNextChar(Lexer);
      While (Not IsSpace(TLexer_PeekNextChar(Lexer))) And
        (TLexer_PeekNextChar(Lexer) <> #0) Do
      Begin
        TLexer_MoveNextChar(Lexer);
      End;
      Lexer.CurrentToken.Value :=
        Copy(Lexer.Source, Lexer.CurrentToken.StartPos, Lexer.CurrentPos -
        Lexer.CurrentToken.StartPos + 1);
      Result := True;
      Exit;
    End;
    Lexer.CurrentToken.Kind := eNum;
    Lexer.CurrentToken.Value :=
      Copy(Lexer.Source, Lexer.CurrentToken.StartPos, Lexer.CurrentPos -
      Lexer.CurrentToken.StartPos + 1);
    Result := True;
    Exit;
  End;
  Result := False;
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eNum;
  Result.Parser := Parse;
End;

End.
