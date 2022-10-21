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
  StringUtils, TypeDef;

Function Parse(Lexer: PLexer): Boolean;
Var
  mCh: Char;
  mSavePoint: TSize;
Label
  S1, S2, S3, S4, S5, S6, S7, S8, S9, SDone;
Begin
  Result := True;
  Lexer.CurrentToken.StartPos := Lexer.NextPos;
  mSavePoint := 0;
  S1:
  Begin
    mCh := TLexer_GetNextChar(Lexer);
    If IsDigit(mCh) Then
      Goto S2;
    If mCh = '$' Then
      Goto S9;
    Result := False;
    Goto SDone;
  End;
  S2:
  Begin
    mSavePoint := Lexer.NextPos;
    mCh := TLexer_GetNextChar(Lexer);
    If IsDigit(mCh) Then
      Goto S2;
    If mCh = '.' Then
      Goto S3;
    If mCh In ['e', 'E'] Then
      Goto S5;
    Goto SDone;
  End;
  S3:
  Begin
    mCh := TLexer_GetNextChar(Lexer);
    If IsDigit(mCh) Then
      Goto S4;
    If mCh In ['e', 'E'] Then
      Goto S5;
    Result := False;
    Goto SDone;
  End;
  S4:
  Begin
    mSavePoint := Lexer.NextPos;
    mCh := TLexer_GetNextChar(Lexer);
    If IsDigit(mCh) Then
      Goto S4;
    If mCh In ['e', 'E'] Then
      Goto S5;
    Goto SDone;
  End;
  S5:
  Begin
    mCh := TLexer_GetNextChar(Lexer);
    If mCh In ['+', '-'] Then
      Goto S6;
    If IsDigit(mCh) Then
      Goto S7;
    Result := False;
    Goto SDone;
  End;
  S6:
  Begin
    mCh := TLexer_GetNextChar(Lexer);
    If IsDigit(mCh) Then
      Goto S7;
    Result := False;
    Goto SDone;
  End;
  S7:
  Begin
    mSavePoint := Lexer.NextPos;
    mCh := TLexer_GetNextChar(Lexer);
    If IsDigit(mCh) Then
      Goto S7;
    Goto SDone;
  End;
  S8:
  Begin
    mCh := TLexer_GetNextChar(Lexer);
    If IsHexDigit(mCh) Then
      Goto S9;
    Result := False;
    Goto SDone;
  End;
  S9:
  Begin
    mSavePoint := Lexer.NextPos;
    mCh := TLexer_GetNextChar(Lexer);
    If IsHexDigit(mCh) Then
      Goto S9;
    Goto SDone;
  End;
  SDone:
    TLexer_Retract(Lexer);
  If (Not Result) And (mSavePoint <> 0) Then
  Begin
    Result := True;
    Lexer.NextPos := mSavePoint;
  End;
  If Result Then
  Begin
    Lexer.CurrentToken.Value :=
      Copy(Lexer.Source, Lexer.CurrentToken.StartPos, Lexer.NextPos -
      Lexer.CurrentToken.StartPos);
  End;
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eNum;
  Result.Parser := Parse;
End;

End.
