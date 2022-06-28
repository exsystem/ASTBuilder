Unit Lexer;

{$MODE DELPHI}

Interface

Type
  TTokenKind = (
    eUndefined,
    eAdd, eSub, eMul, eDiv,
    eLParent, eRParent,
    eNum,
    eEof
    );

  TToken = Record
    Kind: TTokenKind;
    Value: String;
    StartPos: UInt32;
  End;

  PLexer = ^TLexer;

  TLexer = Record
    Source: String;
    CurrentPos: UInt32;
    CurrentChar: Char;
  End;

Function TLexer_Create(Const Source: String): PLexer;
Procedure TLexer_Destroy(Var Self: PLexer);
Function TLexer_GetNextToken(Var Self: PLexer; Out Token: TToken): Boolean;
Procedure TLexer_MoveNextChar(Var Self: PLexer);
Function TLexer_PeekNextChar(Var Self: PLexer): Char;

Implementation

Uses
  StringUtils;

Function TLexer_Create(Const Source: String): PLexer;
Begin
  New(Result);
  Result.Source := Source + #0;
  Result.CurrentPos := 0;
  Result.CurrentChar := '#';
End;

Function TLexer_GetNextToken(Var Self: PLexer; Out Token: TToken): Boolean;
Begin
  Repeat
    TLexer_MoveNextChar(Self);
  Until Not IsSpace(Self.CurrentChar);

  Result := True;
  If Self.CurrentChar = #0 Then
  Begin
    Token.Kind := eEof;
    Token.Value := 'EOF';
    Token.StartPos := Self.CurrentPos;
    Exit(Result);
  End;
  If Self.CurrentChar = '+' Then
  Begin
    Token.Kind := eAdd;
    Token.Value := Self.CurrentChar;
    Token.StartPos := Self.CurrentPos;
    Exit(Result);
  End;
  If Self.CurrentChar = '-' Then
  Begin
    Token.Kind := eSub;
    Token.Value := Self.CurrentChar;
    Token.StartPos := Self.CurrentPos;
    Exit(Result);
  End;
  If Self.CurrentChar = '*' Then
  Begin
    Token.Kind := eMul;
    Token.Value := Self.CurrentChar;
    Token.StartPos := Self.CurrentPos;
    Exit(Result);
  End;
  If Self.CurrentChar = '/' Then
  Begin
    Token.Kind := eDiv;
    Token.Value := Self.CurrentChar;
    Token.StartPos := Self.CurrentPos;
    Exit(Result);
  End;
  If Self.CurrentChar = '(' Then
  Begin
    Token.Kind := eLParent;
    Token.Value := Self.CurrentChar;
    Token.StartPos := Self.CurrentPos;
    Exit(Result);
  End;
  If Self.CurrentChar = ')' Then
  Begin
    Token.Kind := eRParent;
    Token.Value := Self.CurrentChar;
    Token.StartPos := Self.CurrentPos;
    Exit(Result);
  End;
  If IsDigit(Self.CurrentChar) Then
  Begin
    // look self...
    Token.StartPos := Self.CurrentPos;
    While IsDigit(TLexer_PeekNextChar(Self)) Do
    Begin
      TLexer_MoveNextChar(Self);
    End;
    // look after...
    If Not (TLexer_PeekNextChar(Self) In [' ', '+', '-', '*', '/', ')']) Then
    Begin
      Token.Kind := eUndefined;
      TLexer_MoveNextChar(Self);
      While (Not IsSpace(TLexer_PeekNextChar(Self))) And
        (TLexer_PeekNextChar(Self) <> #0) Do
      Begin
        TLexer_MoveNextChar(Self);
      End;
      Token.Value := Copy(Self.Source, Token.StartPos, Self.CurrentPos -
        Token.StartPos + 1);
      Exit(False);
    End;
    Token.Kind := eNum;
    Token.Value := Copy(Self.Source, Token.StartPos, Self.CurrentPos -
      Token.StartPos + 1);
    Exit(Result);
  End;

  Token.StartPos := Self.CurrentPos;
  While (Not IsSpace(TLexer_PeekNextChar(Self))) And (TLexer_PeekNextChar(Self) <> #0) Do
  Begin
    TLexer_MoveNextChar(Self);
  End;
  Token.Kind := eUndefined;
  Token.Value := Copy(Self.Source, Token.StartPos, Self.CurrentPos - Token.StartPos + 1);
  Result := False;
End;

Procedure TLexer_Destroy(Var Self: PLexer);
Begin
  Dispose(Self);
  Self := nil;
End;

Procedure TLexer_MoveNextChar(Var Self: PLexer);
Begin
  Inc(Self.CurrentPos);
  Self.CurrentChar := Self.Source[Self.CurrentPos];
End;

Function TLexer_PeekNextChar(Var Self: PLexer): Char;
Begin
  Result := Self.Source[Succ(Self.CurrentPos)];
End;

End.
