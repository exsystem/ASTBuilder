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
  // look self, case 1: $...
  If Lexer.CurrentChar = '$' Then
  Begin
    Result := True;
    Lexer.CurrentToken.StartPos := Lexer.CurrentPos;
    If IsHexDigit(TLexer_PeekNextChar(Lexer)) Then
    Begin
      Lexer.CurrentToken.Kind := eNum;
      TLexer_MoveNextChar(Lexer);
      While IsHexDigit(TLexer_PeekNextChar(Lexer)) Do
      Begin
        TLexer_MoveNextChar(Lexer);
      End;
    End
    Else
    Begin
      Lexer.CurrentToken.Kind := eUndefined;
    End;
  End
  // look self, case 2: d..., start with a digit.
  Else If IsDigit(Lexer.CurrentChar) Then
  Begin
    Result := True;
    Lexer.CurrentToken.Kind := eNum;
    Lexer.CurrentToken.StartPos := Lexer.CurrentPos;
    While IsDigit(TLexer_PeekNextChar(Lexer)) Do
    Begin
      TLexer_MoveNextChar(Lexer);
    End;
    If TLexer_PeekNextChar(Lexer) = '.' Then
    Begin
      TLexer_MoveNextChar(Lexer);
      While IsDigit(TLexer_PeekNextChar(Lexer)) Do
      Begin
        TLexer_MoveNextChar(Lexer);
      End;
    End;
    If TLexer_PeekNextChar(Lexer) In ['e', 'E'] Then
    Begin
      TLexer_MoveNextChar(Lexer);
      If TLexer_PeekNextChar(Lexer) In ['+', '-'] Then
      Begin
        TLexer_MoveNextChar(Lexer);
        If Not IsDigit(TLexer_PeekNextChar(Lexer)) Then
        Begin
          Lexer.CurrentToken.Kind := eUndefined;
        End;
      End;
      While IsDigit(TLexer_PeekNextChar(Lexer)) Do
      Begin
        TLexer_MoveNextChar(Lexer);
      End;
    End;
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  // look after...
  If (Lexer.CurrentToken.Kind = eNum) And
    (Not (TLexer_PeekNextChar(Lexer) In [' ', '+', '-', '*', '/',
    ')', {'.',} #0])) Then
  Begin
    Lexer.CurrentToken.Kind := eUndefined;
    TLexer_MoveNextChar(Lexer);
    While (Not IsSpace(TLexer_PeekNextChar(Lexer))) And
      (TLexer_PeekNextChar(Lexer) <> #0) Do
    Begin
      TLexer_MoveNextChar(Lexer);
    End;
    Result := True;
  End;

  Lexer.CurrentToken.Value :=
    Copy(Lexer.Source, Lexer.CurrentToken.StartPos, Lexer.CurrentPos -
    Lexer.CurrentToken.StartPos + 1);
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eNum;
  Result.Parser := Parse;
End;

End.
