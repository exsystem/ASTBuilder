Unit Lexer;

{$I define.inc}
Interface

Uses
  TypeDef, Stream, GrmrNode;

Type
  PToken = ^TToken;
  PLexer = ^TLexer;
  PLexer_VMT = ^TLexer_VMT;

  TToken = Record
    Error: PTChar;
    Value: PTChar;
    StartPos: TSize;
    Kind: Pointer;
  End;
  TLexer_Destroy_Proc = Procedure(Self: PLexer);
  TLexer_IsToken_Proc = Function(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
  TLexer_GetNextToken_Proc = Function(Var Self: PLexer): Boolean;

  TLexer_VMT = Record
    Destory: TLexer_Destroy_Proc;
    IsToken: TLexer_IsToken_Proc;
    GetNextToken: TLexer_GetNextToken_Proc;
  End;

  TLexer = Record
    VMT: PLexer_VMT;
    FCaseSensitive: Boolean;
    FStream: PStream;
    CurrentChar: PTChar;
    CurrentCharSize: TSize;
    FLastPeekCharCount: TSize;
    CurrentToken: TToken;
  End;

Procedure TLexer_Create(Var Self: PLexer; Const Source: PStream;
  Const CaseSensitive: Boolean);
Procedure TLexer_Destroy(Var Self: PLexer);
Function TLexer_CompareNextToken(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
Procedure TLexer_Forward(Var Self: PLexer; Const Step: TSize);
Function TLexer_PeekNextChar(Var Self: PLexer): PTChar;
Function TLexer_PeekNextWord(Var Self: PLexer; Const NextWord: PTChar): Boolean;
Function TLexer_GetNextChar(Var Self: PLexer): PTChar;
Procedure TLexer_Retract(Var Self: PLexer; Const Step: TSize);
Function TLexer_GetNextPos(Var Self: PLexer): TSize;
Procedure TLexer_FetchNextToken(Var Self: PLexer; Length: TSize);

Implementation

Uses
  SysUtils, StrUtil, TrmRNode{$IFDEF USE_STRINGS}, strings{$ENDIF};

Procedure TLexer_Create(Var Self: PLexer; Const Source: PStream;
  Const CaseSensitive: Boolean);
Begin
  Self^.FCaseSensitive := CaseSensitive;
  Source^.VMT^.SetPosition(Source, 0);
  Self^.FStream := Source;
  Self^.CurrentChar := nil;
  Self^.CurrentCharSize := 0;
  Self^.FLastPeekCharCount := 0;
  Self^.CurrentToken.Value := TCharStrNew('');
  Self^.CurrentToken.Error := TCharStrNew('');
End;

Procedure TLexer_Destroy(Var Self: PLexer);
Begin
  FreeStr(Self^.CurrentToken.Error);
  FreeStr(Self^.CurrentToken.Value);
  TChar_Deallocate(Self^.CurrentChar);
  Self^.FStream^.VMT^.Destroy(Self^.FStream);
End;

Procedure TLexer_Forward(Var Self: PLexer; Const Step: TSize);
Begin
  Self^.FStream^.VMT^.Forward(Self^.FStream, Step);
End;

Function TLexer_PeekNextChar(Var Self: PLexer): PTChar;
Begin
  Result := TLexer_GetNextChar(Self);
  If Result^.Bytes[0] <> 0 Then
    Self^.FStream^.VMT^.Rewind(Self^.FStream, 1);
End;

Function TLexer_GetNextChar(Var Self: PLexer): PTChar;
Var
  mBytes: Array[0..3] Of Byte;
  mReadCount, mByteCount: TSize;
Begin
  TChar_Deallocate(Self^.CurrentChar);
  mReadCount := Self^.FStream^.VMT^.Read(Self^.FStream, mBytes[0], 1,
    mByteCount);
  If (mReadCount = 0) Or (mByteCount = 0) Then
  Begin
    Self^.CurrentChar := TChar_Allocate(1);
    Self^.CurrentChar^.Bytes[0] := 0;
    Self^.CurrentCharSize := 0;
  End
  Else
  Begin
    Self^.CurrentChar := TChar_Allocate(mByteCount);
    Move(mBytes[0], Self^.CurrentChar^, mByteCount);
    Self^.CurrentCharSize := mByteCount;
  End;
  Result := Self^.CurrentChar;
End;

Function TLexer_PeekNextWord(Var Self: PLexer; Const NextWord: PTChar): Boolean;
Var
  I, J: TSize;
  mNextWordLength, mByteOffset, mCharSize, mCharsRead: TSize;
  mChar: PTChar;
Begin
  mNextWordLength := TCharStrLen(NextWord);
  mByteOffset := 0;
  mCharsRead := 0;
  Result := True;
  While mByteOffset < mNextWordLength Do
  Begin
    mChar := TLexer_GetNextChar(Self);
    mCharSize := Self^.CurrentCharSize;
    If mCharSize = 0 Then
    Begin
      Result := False;
      Break;
    End;
    Inc(mCharsRead);
    If mByteOffset + mCharSize > mNextWordLength Then
    Begin
      Result := False;
      Break;
    End;
    For J := 0 To mCharSize - 1 Do
    Begin
      I := PByte(NextWord)[mByteOffset + J];
      If Not Self^.FCaseSensitive Then
      Begin
        If Lower(I) <> Lower(PByte(mChar)[J]) Then
        Begin
          Result := False;
          Break;
        End;
      End
      Else If I <> PByte(mChar)[J] Then
      Begin
        Result := False;
        Break;
      End;
    End;
    If Not Result Then
      Break;
    Inc(mByteOffset, mCharSize);
  End;
  If mCharsRead > 0 Then
    Self^.FStream^.VMT^.Rewind(Self^.FStream, mCharsRead);
  Self^.FLastPeekCharCount := 0;
  If Result Then
    Self^.FLastPeekCharCount := mCharsRead;
End;

Function TLexer_CompareNextToken(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
Begin
  Self^.VMT^.GetNextToken(Self);
  Result := Self^.VMT^.IsToken(Self, TokenKind);
End;

Procedure TLexer_Retract(Var Self: PLexer; Const Step: TSize);
Begin
  Self^.FStream^.VMT^.Rewind(Self^.FStream, Step);
End;

Function TLexer_GetNextPos(Var Self: PLexer): TSize;
Begin
  Result := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
End;

Procedure TLexer_FetchNextToken(Var Self: PLexer; Length: TSize);
Var
  mDummy: TSize;
Begin
  FreeStr(Self^.CurrentToken.Value);
  Self^.CurrentToken.Value := CreateStr(Length * 4);
  Self^.FStream^.VMT^.SetPosition(Self^.FStream, Self^.CurrentToken.StartPos);
  Self^.FStream^.VMT^.Read(Self^.FStream, Self^.CurrentToken.Value^, Length, mDummy);
  PByte(Self^.CurrentToken.Value)[mDummy] := 0;
End;

End.
