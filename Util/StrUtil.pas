{ StringUtils.pas }
Unit StrUtil;

{$I define.inc}

Interface

Uses
  TypeDef;

Function IsSpace(Const Ch: Byte): Boolean;
Function IsDigit(Const Ch: Byte): Boolean;
Function IsHexDigit(Const Ch: Byte): Boolean;
Function IsIdInitialChar(Const Ch: Byte): Boolean;
Function IsIdChar(Const Ch: Byte): Boolean;
Function Lower(Const Ch: Byte): Byte;
Function IsTermIdInitialChar(Const Ch: Byte): Boolean;
Function IsNonTermIdInitialChar(Const Ch: Byte): Boolean;
Function EscapeChar(Source: Byte): Byte;
Function TCharStrLen(S: PTChar): TSize; { Encoded character count }
Function TCharStrByteLen(S: PTChar): TSize;
Function TCharStrCharCount(S: PTChar): TSize;
Function TCharStrByteOffset(S: PTChar; CharOffset: TSize): TSize;
Function TCharStrAnsiByteLen(Const Source: AnsiString;
  Encoding: TEncodingKind): TSize;
Function TCharStrToAnsiString(S: PTChar): AnsiString;
Function TCharStrNew(Const Source: PTChar): PTChar; Overload;
Function TCharStrNew(Const Source: AnsiString): PTChar; Overload;
Function TCharStrNewAnsiEncoded(Const Source: AnsiString;
  Encoding: TEncodingKind): PTChar;
Function TCharStrNewEncoded(Const Source: AnsiString;
  Encoding: TEncodingKind): PTChar;
Function TCharStrComp(Const LHS, RHS: PTChar): Integer; Overload;
Function TCharStrComp(Const LHS: PTChar; Const RHS: AnsiString): Integer; Overload;
Function TCharStrCopy(Dest, Source: PTChar): PTChar; Overload;
Function TCharStrCopy(Dest: PTChar; Const Source: AnsiString): PTChar; Overload;
Function TCharStrCat(Dest, Source: PTChar): PTChar; Overload;
Function TCharStrCat(Dest: PTChar; Const Source: AnsiString): PTChar; Overload;
Function CreateStr(Len: TSize): PTChar;
Function CreateStrEncoded(Len: TSize; Encoding: TEncodingKind): PTChar;
Function ReallocStr(S: PTChar; Len: TSize): PTChar;
Procedure FreeStr(S: PTChar);
Function SubStr(S: PTChar; FromIndex: TSize; Len: TSize): PTChar;

Implementation

Uses
  SysUtils;

Procedure TCharStr_RequireGlobalEncoding(Encoding: TEncodingKind);
Begin
  If Encoding <> TChar_GetGlobalEncoding Then
    Raise EConvertError.CreateFmt(
      'String encoding (%d) does not match the global encoding (%d).',
      [Ord(Encoding), Ord(TChar_GetGlobalEncoding)]);
End;

Function IsSpace(Const Ch: Byte): Boolean;
Begin
  Result := Ch In [Ord(' '), 9, 10, 11, 12, 13];
End;

Function IsDigit(Const Ch: Byte): Boolean;
Begin
  Result := Ch In [Ord('0') .. Ord('9')];
End;

Function IsHexDigit(Const Ch: Byte): Boolean;
Begin
  Result := Ch In [Ord('0') .. Ord('9'), Ord('a') .. Ord('f'),
    Ord('A') .. Ord('F')];
End;

Function IsIdInitialChar(Const Ch: Byte): Boolean;
Begin
  Result := (Ch = Ord('_')) Or (Ch In [Ord('a') .. Ord('z'), Ord('A') .. Ord('Z')]);
End;

Function IsIdChar(Const Ch: Byte): Boolean;
Begin
  Result := IsIdInitialChar(Ch) Or (Ch In [Ord('0') .. Ord('9')]);
End;

Function Lower(Const Ch: Byte): Byte;
Begin
  If (Ch >= Ord('A')) And (Ch <= Ord('Z')) Then
    Result := Ch - Ord('A') + Ord('a')
  Else
    Result := Ch;
End;

Function IsTermIdInitialChar(Const Ch: Byte): Boolean;
Begin
  Result := Ch In [Ord('A') .. Ord('Z')];
End;

Function IsNonTermIdInitialChar(Const Ch: Byte): Boolean;
Begin
  Result := Ch In [Ord('a') .. Ord('z')];
End;

Function EscapeChar(Source: Byte): Byte;
Begin
  Case Source Of
    Ord('a'): Result := 7;
    Ord('b'): Result := 8;
    Ord('t'): Result := 9;
    Ord('n'): Result := 10;
    Ord('v'): Result := 11;
    Ord('f'): Result := 12;
    Ord('r'): Result := 13;
    Else Result := Source;
  End;
End;

Function TCharStrByteLen(S: PTChar): TSize;
Var
  I, mByteLength, mCharSize: TSize;
  mEncoding: TEncodingKind;
Begin
  Result := 0;
  If S = nil Then
    Exit;
  mEncoding := TChar_GetEncoding(S);
  mByteLength := TChar_GetByteLength(S);
  I := 0;
  While I < mByteLength Do
  Begin
    If (mEncoding In [ekASCII, ekUTF8, ekGBK]) And (PByte(S)[I] = 0) Then
      Break;
    If (mEncoding In [ekUTF16LE, ekUTF16BE]) And
      (I + 1 < mByteLength) And (PByte(S)[I] = 0) And
      (PByte(S)[I + 1] = 0) Then
      Break;
    If Not TChar_GetEncodedSize(mEncoding, @PByte(S)[I],
      mByteLength - I, mCharSize) Then
      mCharSize := 1;
    Inc(I, mCharSize);
  End;
  Result := I;
End;

Function TCharStrLen(S: PTChar): TSize;
Var
  I, mCharSize, mByteLength: TSize;
  mEncoding: TEncodingKind;
Begin
  Result := 0;
  If S = nil Then
    Exit;
  mEncoding := TChar_GetEncoding(S);
  mByteLength := TCharStrByteLen(S);
  I := 0;
  While I < mByteLength Do
  Begin
    If Not TChar_GetEncodedSize(mEncoding, @PByte(S)[I],
      mByteLength - I, mCharSize) Then
      mCharSize := 1;
    Inc(Result);
    Inc(I, mCharSize);
  End;
End;

Function TCharStrCharCount(S: PTChar): TSize;
Begin
  Result := TCharStrLen(S);
End;

Function TCharStrByteOffset(S: PTChar; CharOffset: TSize): TSize;
Var
  I, mByteLength, mCharSize, mCharCount: TSize;
  mEncoding: TEncodingKind;
Begin
  Result := 0;
  If S = nil Then
    Exit;
  mEncoding := TChar_GetEncoding(S);
  mByteLength := TCharStrByteLen(S);
  mCharCount := 0;
  While (Result < mByteLength) And (mCharCount < CharOffset) Do
  Begin
    I := Result;
    If Not TChar_GetEncodedSize(mEncoding, @PByte(S)[I],
      mByteLength - I, mCharSize) Then
      mCharSize := 1;
    Inc(Result, mCharSize);
    Inc(mCharCount);
  End;
End;

Function TCharStrAnsiByteLen(Const Source: AnsiString;
  Encoding: TEncodingKind): TSize;
Begin
  Result := Length(Source);
  If Encoding In [ekUTF16LE, ekUTF16BE] Then
    Result := Result * 2;
End;

Function TCharStrToAnsiString(S: PTChar): AnsiString;
Var
  mLength: TSize;
Begin
  mLength := TCharStrByteLen(S);
  SetLength(Result, mLength);
  If mLength > 0 Then
    Move(S^, Result[1], mLength);
End;

Function TCharStrNew(Const Source: PTChar): PTChar;
Var
  mLength: TSize;
  mEncoding: TEncodingKind;
Begin
  If Source = nil Then
  Begin
    Result := nil;
    Exit;
  End;
  mLength := TCharStrByteLen(Source);
  mEncoding := TChar_GetEncoding(Source);
  Result := CreateStrEncoded(mLength, mEncoding);
  If mLength > 0 Then
    Move(Source^, Result^, mLength);
  TChar_SetByteLength(Result, mLength);
End;

Function TCharStrNew(Const Source: AnsiString): PTChar;
Begin
  Result := TCharStrNewAnsiEncoded(Source, TChar_GetGlobalEncoding);
End;

Function TCharStrNewAnsiEncoded(Const Source: AnsiString;
  Encoding: TEncodingKind): PTChar;
Begin
  Result := CreateStrEncoded(TCharStrAnsiByteLen(Source, Encoding), Encoding);
  TCharStrCat(Result, Source);
End;

Function TCharStrNewEncoded(Const Source: AnsiString;
  Encoding: TEncodingKind): PTChar;
Var
  mLength: TSize;
Begin
  mLength := Length(Source);
  Result := CreateStrEncoded(mLength, Encoding);
  If mLength > 0 Then
    Move(Source[1], Result^, mLength);
  TChar_SetByteLength(Result, mLength);
End;

Function TCharStrComp(Const LHS, RHS: PTChar): Integer;
Var
  mLeft, mRight: PByte;
  I, mLeftLength, mRightLength: TSize;
Begin
  mLeftLength := TCharStrByteLen(LHS);
  mRightLength := TCharStrByteLen(RHS);
  mLeft := PByte(LHS);
  mRight := PByte(RHS);
  I := 0;
  While (I < mLeftLength) And (I < mRightLength) And (mLeft^ = mRight^) Do
  Begin
    Inc(mLeft);
    Inc(mRight);
    Inc(I);
  End;
  If I < mLeftLength Then
  Begin
    If I < mRightLength Then
      Result := Integer(mLeft^) - Integer(mRight^)
    Else
      Result := Integer(mLeft^);
  End
  Else If I < mRightLength Then
    Result := -Integer(mRight^)
  Else
    Result := 0;
End;

Function TCharStrComp(Const LHS: PTChar; Const RHS: AnsiString): Integer;
Var
  mRight: PTChar;
Begin
  If LHS = nil Then
    mRight := TCharStrNew(RHS)
  Else
    mRight := TCharStrNewAnsiEncoded(RHS, TChar_GetEncoding(LHS));
  Result := TCharStrComp(LHS, mRight);
  FreeStr(mRight);
End;

Function TCharStrCopy(Dest, Source: PTChar): PTChar;
Var
  mLength: TSize;
Begin
  Result := Dest;
  mLength := TCharStrByteLen(Source);
  If mLength > 0 Then
    Move(Source^, Dest^, mLength);
  TChar_SetByteLength(Dest, mLength);
End;

Function TCharStrCopy(Dest: PTChar; Const Source: AnsiString): PTChar;
Var
  mLength, I: TSize;
  mEncoding: TEncodingKind;
Begin
  Result := Dest;
  mEncoding := TChar_GetGlobalEncoding;
  mLength := TCharStrAnsiByteLen(Source, mEncoding);
  If mEncoding In [ekUTF16LE, ekUTF16BE] Then
  Begin
    For I := 1 To Length(Source) Do
    Begin
      If mEncoding = ekUTF16LE Then
      Begin
        PByte(Dest)[(I - 1) * 2] := Byte(Source[I]);
        PByte(Dest)[(I - 1) * 2 + 1] := 0;
      End
      Else
      Begin
        PByte(Dest)[(I - 1) * 2] := 0;
        PByte(Dest)[(I - 1) * 2 + 1] := Byte(Source[I]);
      End;
    End;
  End
  Else If mLength > 0 Then
    Move(Source[1], Dest^, mLength);
  TChar_SetByteLength(Dest, mLength);
End;

Function TCharStrCat(Dest, Source: PTChar): PTChar;
Var
  mOffset, mLength: TSize;
Begin
  Result := Dest;
  mOffset := TCharStrByteLen(Dest);
  mLength := TCharStrByteLen(Source);
  If mLength > 0 Then
    Move(Source^, PByte(Dest)[mOffset], mLength);
  TChar_SetByteLength(Dest, mOffset + mLength);
End;

Function TCharStrCat(Dest: PTChar; Const Source: AnsiString): PTChar;
Var
  mOffset, mLength, I: TSize;
  mEncoding: TEncodingKind;
Begin
  Result := Dest;
  mOffset := TCharStrByteLen(Dest);
  mEncoding := TChar_GetEncoding(Dest);
  If mEncoding In [ekUTF16LE, ekUTF16BE] Then
  Begin
    mLength := Length(Source) * 2;
    For I := 1 To Length(Source) Do
    Begin
      If mEncoding = ekUTF16LE Then
      Begin
        PByte(Dest)[mOffset + (I - 1) * 2] := Byte(Source[I]);
        PByte(Dest)[mOffset + (I - 1) * 2 + 1] := 0;
      End
      Else
      Begin
        PByte(Dest)[mOffset + (I - 1) * 2] := 0;
        PByte(Dest)[mOffset + (I - 1) * 2 + 1] := Byte(Source[I]);
      End;
    End;
  End
  Else
  Begin
    mLength := Length(Source);
    If mLength > 0 Then
      Move(Source[1], PByte(Dest)[mOffset], mLength);
  End;
  TChar_SetByteLength(Dest, mOffset + mLength);
End;

Function CreateStr(Len: TSize): PTChar;
Begin
  Result := CreateStrEncoded(Len, TChar_GetGlobalEncoding);
End;

Function CreateStrEncoded(Len: TSize; Encoding: TEncodingKind): PTChar;
Var
  mTerminatorSize: TSize;
Begin
  TCharStr_RequireGlobalEncoding(Encoding);
  If Encoding In [ekUTF16LE, ekUTF16BE] Then
    mTerminatorSize := 2
  Else
    mTerminatorSize := 1;
  Result := TChar_AllocateEncoded(Len + mTerminatorSize, Encoding);
  FillChar(Result^, Len + mTerminatorSize, 0);
  TChar_SetByteLength(Result, 0);
End;

Function ReallocStr(S: PTChar; Len: TSize): PTChar;
Var
  mLength: TSize;
  mEncoding: TEncodingKind;
Begin
  If S = nil Then
    mEncoding := TChar_GetGlobalEncoding
  Else
    mEncoding := TChar_GetEncoding(S);
  Result := CreateStrEncoded(Len, mEncoding);
  mLength := TCharStrByteLen(S);
  If mLength > Len Then
    mLength := Len;
  If mLength > 0 Then
    Move(S^, Result^, mLength);
  TChar_SetByteLength(Result, mLength);
  FreeStr(S);
End;

Procedure FreeStr(S: PTChar);
Begin
  If S <> nil Then
    TChar_Deallocate(S);
End;

Function SubStr(S: PTChar; FromIndex: TSize; Len: TSize): PTChar;
Begin
  Result := CreateStrEncoded(Len, TChar_GetEncoding(S));
  If Len > 0 Then
    Move(PByte(S)[FromIndex], Result^, Len);
  TChar_SetByteLength(Result, Len);
End;

End.
