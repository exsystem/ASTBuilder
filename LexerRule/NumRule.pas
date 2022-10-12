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
  If TLexer_PeekNextChar(Lexer) = '$' Then
  Begin
    Result := True;
    Lexer.CurrentToken.StartPos := Lexer.NextPos;
    TLexer_Forward(Lexer);
    If IsHexDigit(TLexer_PeekNextChar(Lexer)) Then
    Begin
      TLexer_Forward(Lexer);
      While IsHexDigit(TLexer_PeekNextChar(Lexer)) Do
      Begin
        TLexer_Forward(Lexer);
      End;
    End
    Else
    Begin
      Lexer.CurrentToken.Error := 'Illegal hex number.';
    End;
  End
  // look self, case 2: d..., start with a digit.
  Else If IsDigit(TLexer_PeekNextChar(Lexer)) Then
  Begin
    Result := True;
    Lexer.CurrentToken.StartPos := Lexer.NextPos;
    TLexer_Forward(Lexer);
    While IsDigit(TLexer_PeekNextChar(Lexer)) Do
    Begin
      TLexer_Forward(Lexer);
    End;
    If TLexer_PeekNextChar(Lexer) = '.' Then
    Begin
      TLexer_Forward(Lexer);
      While IsDigit(TLexer_PeekNextChar(Lexer)) Do
      Begin
        TLexer_Forward(Lexer);
      End;
    End;
    If TLexer_PeekNextChar(Lexer) In ['e', 'E'] Then
    Begin
      TLexer_Forward(Lexer);
      If TLexer_PeekNextChar(Lexer) In ['+', '-'] Then
      Begin
        TLexer_Forward(Lexer);
        If Not IsDigit(TLexer_PeekNextChar(Lexer)) Then
        Begin
          Lexer.CurrentToken.Kind := eUndefined;
        End;
      End;
      While IsDigit(TLexer_PeekNextChar(Lexer)) Do
      Begin
        TLexer_Forward(Lexer);
      End;
    End;
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  // look after...
(*
  If (Lexer.CurrentToken.Error = '') And
    (Not (TLexer_PeekNextChar(Lexer) In [' ', '+', '-', '*', '/',
    ')', {'.',} #0])) Then
  Begin
    Lexer.CurrentToken.Error := 'Illegal number.';
    TLexer_Forward(Lexer);
    While (Not IsSpace(TLexer_PeekNextChar(Lexer))) And
      (TLexer_PeekNextChar(Lexer) <> #0) Do
    Begin
      TLexer_Forward(Lexer);
    End;
    Result := True;
  End;
*)

  Lexer.CurrentToken.Value :=
    Copy(Lexer.Source, Lexer.CurrentToken.StartPos, Lexer.NextPos -
    Lexer.CurrentToken.StartPos);
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eNum;
  Result.Parser := Parse;
End;

End.
