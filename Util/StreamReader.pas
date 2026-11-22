{ Stream Reader Unit for handling files with different encodings }
{ Modern stream reader pattern - similar to Java/C# approach }

Unit StreamReader;

{$I define.inc}

Interface

Uses
  SysUtils, TypeDef, Stream;

Type
  PStreamReader = ^TStreamReader;

  TStreamReader = Record
    Parent: TStream;                { Base stream interface }
    FFile: File Of Byte;
    FEncoding: TEncodingKind;       { Current encoding }
    FEof: Boolean;
    FPosition: TSize; { Position in characters }
    FByteStart: TSize;
    FCharBytePositions: Array Of TSize;
    FCharBytePositionCount: TSize;
  End;

  { Encoding detection result }
  TEncodingInfo = Record
    Kind: TEncodingKind;
    BOMSize: TSize;  { Size of Byte Order Mark }
  End;

Function TStreamReader_GetUTF16CharSize(FirstByte, SecondByte: Byte;
  Encoding: TEncodingKind): TSize;

{ ============================================================
  TStreamReader API functions
============================================================ }

Procedure TStreamReader_Create(Var Self: PStreamReader; Filename: String); Overload;
Procedure TStreamReader_Create(Var Self: PStreamReader; Filename: String;
  Encoding: TEncodingKind); Overload;
Procedure TStreamReader_Destroy(Const Self: PStream);
{ Read a character as raw bytes, returns number of bytes read (0 = EOF) }
Function TStreamReader_ReadChar(Const Self: PStreamReader; Const Ch: PByte;
  MaxSize: TSize): Integer;
Function TStreamReader_GetPosition(Const Self: PStream): TSize;
Procedure TStreamReader_SetPosition(Const Self: PStream; Value: TSize);
Function TStreamReader_GetLength(Const Self: PStream): TSize;
Function TStreamReader_IsEof(Const Self: PStream): Boolean;
Function TStreamReader_Read(Const Self: PStream; Var Data; Const Length: TSize; Var Size: TSize): TSize;
Function TStreamReader_Write(Const Self: PStream; Var Data; Const Length: TSize; Var Size: TSize): TSize;
Function TStreamReader_Forward(Const Self: PStream; Offset: TSize): Boolean;
Function TStreamReader_Rewind(Const Self: PStream; Offset: TSize): Boolean;
{ ============================================================
  Utility functions for encoding detection
============================================================ }
Function TStreamReader_DetectEncoding(Const Filename: String;
  Out Info: TEncodingInfo): Boolean;
Function TStreamReader_GetEncodingName(Encoding: TEncodingKind): String;
{ ============================================================ }
Function TStreamReader_ReadCharToString(Const Self: PStreamReader;
  Out Ch: String): Boolean;
Function TStreamReader_ReadLine(Const Self: PStreamReader; Out Line: String): Boolean;
Function TStreamReader_ReadAllText(Const Self: PStreamReader; Out Text: String): TSize;

Implementation

Var
  mTStreamReader_VMT: TStream_VMT;

Function TStreamReader_GetUTF16CharSize(FirstByte, SecondByte: Byte;
  Encoding: TEncodingKind): TSize;
Var
  mCodeUnit: Word;
Begin
  If Encoding = ekUTF16LE Then
    mCodeUnit := FirstByte Or (SecondByte Shl 8)
  Else
    mCodeUnit := (FirstByte Shl 8) Or SecondByte;
  If (mCodeUnit >= $D800) And (mCodeUnit <= $DBFF) Then
    Result := 4
  Else
    Result := 2;
End;

{ ============================================================
  Internal helper functions
============================================================ }

{ Get number of bytes in a UTF-8 character based on first byte }
Function TStreamReader_GetUTF8CharSize(FirstByte: Byte): TSize;
Begin
  If (FirstByte And $80) = $00 Then
    Result := 1   { ASCII: 0xxxxxxx }
  Else If (FirstByte >= $C2) And (FirstByte <= $DF) Then
    Result := 2   { 2-byte UTF-8: 110xxxxx 10xxxxxx }
  Else If (FirstByte >= $E0) And (FirstByte <= $EF) Then
    Result := 3   { 3-byte UTF-8: 1110xxxx 10xxxxxx 10xxxxxx }
  Else If (FirstByte >= $F0) And (FirstByte <= $F4) Then
    Result := 4   { 4-byte UTF-8: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx }
  Else
    Result := 1;
End;

{ Get number of bytes in a GBK character based on first byte }
Function TStreamReader_GetGBKCharSize(FirstByte: Byte): TSize;
Begin
  If (FirstByte And $80) = $00 Then
    Result := 1   { ASCII: 0xxxxxxx }
  Else If (FirstByte >= $81) And (FirstByte <= $FE) Then
    Result := 2   { GBK: first byte >= 0x81 }
  Else
    Result := 1;
End;

{ Get encoding name }
Function TStreamReader_GetEncodingName(Encoding: TEncodingKind): String;
Begin
  Case Encoding Of
    ekASCII: Result := 'ASCII';
    ekUTF8: Result := 'UTF-8';
    ekUTF16LE: Result := 'UTF-16 LE';
    ekUTF16BE: Result := 'UTF-16 BE';
    ekGBK: Result := 'GBK (Chinese)';
    Else
      Result := 'Unknown';
  End;
End;

{ Detect encoding from file BOM (Byte Order Mark) }
Function TStreamReader_DetectEncoding(Const Filename: String;
  Out Info: TEncodingInfo): Boolean;
Var
  F: File Of Byte;
  mBytes: Array[0..3] Of Byte;
  mNumRead: Integer;
Begin
  Result := False;
  Info.Kind := ekUTF8;
  Info.BOMSize := 0;

  If Not FileExists(Filename) Then
    Exit;

  AssignFile(F, Filename);
  Reset(F, SizeOf(Byte));
  Try
    BlockRead(F, mBytes[0], 4, mNumRead);
    If mNumRead >= 2 Then
    Begin
      { UTF-16 LE BOM: FF FE }
      If (mBytes[0] = $FF) And (mBytes[1] = $FE) Then
      Begin
        Info.Kind := ekUTF16LE;
        Info.BOMSize := 2;
        Result := True;
        Exit;
      End;

      { UTF-16 BE BOM: FE FF }
      If (mBytes[0] = $FE) And (mBytes[1] = $FF) Then
      Begin
        Info.Kind := ekUTF16BE;
        Info.BOMSize := 2;
        Result := True;
        Exit;
      End;

      { UTF-8 BOM: EF BB BF }
      If (mNumRead >= 3) And (mBytes[0] = $EF) And (mBytes[1] = $BB) And
        (mBytes[2] = $BF) Then
      Begin
        Info.Kind := ekUTF8;
        Info.BOMSize := 3;
        Result := True;
        Exit;
      End;

      { No BOM detected, default to UTF-8 }
      Info.Kind := ekUTF8;
      Info.BOMSize := 0;
      Result := True;
    End;
  Finally
    CloseFile(F);
  End;
End;

{ ============================================================
  UTF-8 conversion functions
============================================================ }

Function TStreamReader_ReadUTF8Char(Const Bytes: PByte; ByteCount: TSize;
  Out Ch: String): TSize;
Var
  mSize, I: TSize;
  mCodePoint: Cardinal;
Begin
  Result := 0;
  If ByteCount < 1 Then
    Exit;

  mSize := TStreamReader_GetUTF8CharSize(Bytes[0]);
  If mSize > ByteCount Then
    mSize := ByteCount;

  SetLength(Ch, mSize);
  Move(Bytes^, Ch[1], mSize);

  If mSize = 1 Then
  Begin
    Result := 1;
    Exit;
  End;

  { Decode to CodePoint }
  mCodePoint := 0;
  For I := 0 To mSize - 1 Do
  Begin
    mCodePoint := (mCodePoint Shl 6) Or (Bytes[I] And $3F);
    If I = 0 Then
      mCodePoint := mCodePoint And ((1 Shl (8 - mSize)) - 1);
  End;

  Result := mSize;
End;

{ ============================================================
  GBK conversion functions (simplified)
    Note: This is a simplified implementation. A full GBK table
    would be needed for complete coverage.
============================================================ }

Function TStreamReader_ReadGBKChar(Const Bytes: PByte; ByteCount: TSize;
  Out Ch: String): TSize;
Var
  mSize: TSize;
Begin
  Result := 0;
  If ByteCount < 1 Then
    Exit;

  mSize := TStreamReader_GetGBKCharSize(Bytes[0]);
  If mSize > ByteCount Then
    mSize := ByteCount;

  SetLength(Ch, mSize);
  Move(Bytes^, Ch[1], mSize);

  Result := mSize;
End;

{ ============================================================
  TStreamReader implementation
============================================================ }

Procedure TStreamReader_Destroy(Const Self: PStream);
Begin
  CloseFile(PStreamReader(Self)^.FFile);
  SetLength(PStreamReader(Self)^.FCharBytePositions, 0);
End;

Function TStreamReader_ReadChar(Const Self: PStreamReader; Const Ch: PByte;
  MaxSize: TSize): Integer;
Var
  mByteBuf: Array[0..3] Of Byte;
  mBytesRead, I, mCharSize, mByteCount: Integer;
  mValidatedSize: TSize;
Begin
  Result := 0;

  If Self.FEof Then
    Exit;

  mByteCount := 0;
  BlockRead(Self.FFile, mByteBuf[0], 1, mBytesRead);
  If mBytesRead = 0 Then
  Begin
    Self.FEof := True;
    Exit;
  End;
  mByteCount := 1;

  Case Self.FEncoding Of
    ekASCII:
      mCharSize := 1;
    ekUTF8:
      mCharSize := TStreamReader_GetUTF8CharSize(mByteBuf[0]);
    ekGBK:
      mCharSize := TStreamReader_GetGBKCharSize(mByteBuf[0]);
    ekUTF16LE, ekUTF16BE:
    Begin
      BlockRead(Self.FFile, mByteBuf[1], 1, mBytesRead);
      If mBytesRead = 0 Then
      Begin
        Self.FEof := True;
        mCharSize := 1;
      End
      Else
      Begin
        mByteCount := 2;
        mCharSize := TStreamReader_GetUTF16CharSize(mByteBuf[0],
          mByteBuf[1], Self.FEncoding);
      End;
    End;
    Else
      mCharSize := 1;
  End;

  For I := mByteCount To mCharSize - 1 Do
  Begin
    BlockRead(Self.FFile, mByteBuf[I], 1, mBytesRead);
    If mBytesRead = 0 Then
    Begin
      Self.FEof := True;
      Break;
    End;
    Inc(mByteCount);
  End;

  If Not TChar_GetEncodedSize(Self.FEncoding, @mByteBuf[0], mByteCount,
    mValidatedSize) Or (mValidatedSize <> mByteCount) Then
    Raise EConvertError.Create('Invalid or truncated ' +
      TStreamReader_GetEncodingName(Self.FEncoding) + ' character.');

  If mByteCount <= MaxSize Then
  Begin
    Move(mByteBuf[0], Ch^, mByteCount);
    Result := mByteCount;
    Inc(Self.FPosition);
    If Self.FPosition = Self.FCharBytePositionCount Then
    Begin
      If Self.FCharBytePositionCount = Length(Self.FCharBytePositions) Then
      Begin
        If Length(Self.FCharBytePositions) = 0 Then
          SetLength(Self.FCharBytePositions, 1)
        Else
          SetLength(Self.FCharBytePositions,
            Length(Self.FCharBytePositions) * 2);
      End;
      Self.FCharBytePositions[Self.FCharBytePositionCount] :=
        FilePos(Self.FFile);
      Inc(Self.FCharBytePositionCount);
    End;
  End
  Else
  Begin
    Result := -1;
  End;
End;

{ Read a character and return as string (raw bytes) }
Function TStreamReader_ReadCharToString(Const Self: PStreamReader;
  Out Ch: String): Boolean;
Var
  mBuf: Array[0..3] Of Byte;
  mBytesRead: Integer;
Begin
  mBytesRead := TStreamReader_ReadChar(Self, @mBuf[0], SizeOf(mBuf));
  Result := mBytesRead > 0;
  If Result Then
  Begin
    SetLength(Ch, mBytesRead);
    Move(mBuf[0], Ch[1], mBytesRead);
  End
  Else
    Ch := '';
End;

Function TStreamReader_ReadLine(Const Self: PStreamReader; Out Line: String): Boolean;
Var
  mBytes: Array Of Byte;
  mByteCount, mByteCap: TSize;
  mBytesRead, mNextPosition: TSize;
  mByteData: Array[0..3] Of Byte;
  mLineEndFound, mReadAny, mIsCR, mIsLF: Boolean;
Begin
  Result := False;
  Line := '';
  mByteCap := 256;
  SetLength(mBytes, mByteCap);
  mByteCount := 0;
  mLineEndFound := False;
  mReadAny := False;

  While Not mLineEndFound Do
  Begin
    mBytesRead := TStreamReader_ReadChar(Self, @mByteData[0], SizeOf(mByteData));
    If mBytesRead <= 0 Then
      Break;
    mReadAny := True;

    If Self.FEncoding In [ekUTF16LE, ekUTF16BE] Then
    Begin
      If Self.FEncoding = ekUTF16LE Then
      Begin
        mIsCR := (mByteData[0] = $0D) And (mByteData[1] = 0);
        mIsLF := (mByteData[0] = $0A) And (mByteData[1] = 0);
      End
      Else
      Begin
        mIsCR := (mByteData[0] = 0) And (mByteData[1] = $0D);
        mIsLF := (mByteData[0] = 0) And (mByteData[1] = $0A);
      End;
    End
    Else
    Begin
      mIsCR := mByteData[0] = $0D;
      mIsLF := mByteData[0] = $0A;
    End;

    If mIsLF Or mIsCR Then
    Begin
      mLineEndFound := True;
      If mIsCR Then
      Begin
        mNextPosition := Self.FPosition;
        mBytesRead := TStreamReader_ReadChar(Self, @mByteData[0], SizeOf(mByteData));
        If Self.FEncoding = ekUTF16LE Then
          mIsLF := (mBytesRead = 2) And (mByteData[0] = $0A) And
            (mByteData[1] = 0)
        Else If Self.FEncoding = ekUTF16BE Then
          mIsLF := (mBytesRead = 2) And (mByteData[0] = 0) And
            (mByteData[1] = $0A)
        Else
          mIsLF := (mBytesRead = 1) And (mByteData[0] = $0A);
        If Not mIsLF Then
        Begin
          TStreamReader_SetPosition(PStream(Self), mNextPosition);
        End;
      End;
    End;

    If Not mLineEndFound Then
    Begin
      If mByteCount + mBytesRead > mByteCap Then
      Begin
        mByteCap := mByteCount + mBytesRead + 256;
        SetLength(mBytes, mByteCap);
      End;
      Move(mByteData[0], mBytes[mByteCount], mBytesRead);
      Inc(mByteCount, mBytesRead);
    End;
  End;

  If mByteCount > 0 Then
  Begin
    SetLength(Line, mByteCount);
    Move(mBytes[0], Line[1], mByteCount);
  End;
  Result := mReadAny;
End;

Function TStreamReader_ReadAllText(Const Self: PStreamReader; Out Text: String): TSize;
Var
  mBytes: Array Of Byte;
  mByteCount, mByteCap: TSize;
  mBytesRead: Integer;
  mByteData: Array[0..3] Of Byte;
Begin
  Result := 0;
  Text := '';
  mByteCap := 4096;
  SetLength(mBytes, mByteCap);
  mByteCount := 0;

  Repeat
  Begin
    mBytesRead := TStreamReader_ReadChar(Self, @mByteData[0], SizeOf(mByteData));
    If mBytesRead <= 0 Then
      Break;

    If mByteCount + mBytesRead > mByteCap Then
    Begin
      mByteCap := mByteCount + mBytesRead + 4096;
      SetLength(mBytes, mByteCap);
    End;

    Move(mByteData[0], mBytes[mByteCount], mBytesRead);
    Inc(mByteCount, mBytesRead);
    Inc(Result);
  End
  Until False;

  If mByteCount > 0 Then
  Begin
    Text := '';
    SetLength(Text, mByteCount);
    System.Move(mBytes[0], Text[1], mByteCount);
  End;
End;

{ Count characters in UTF-8 bytes }
Function CountUTF8Characters(Const Bytes: PByte; ByteCount: TSize): TSize;
Var
  I, mCharSize: TSize;
Begin
  Result := 0;
  I := 0;
  While I < ByteCount Do
  Begin
    mCharSize := TStreamReader_GetUTF8CharSize(Bytes[I]);
    Inc(Result);
    Inc(I, mCharSize);
  End;
End;

{ Count characters in GBK bytes }
Function CountGBKCharacters(Const Bytes: PByte; ByteCount: TSize): TSize;
Var
  I, mCharSize: TSize;
Begin
  Result := 0;
  I := 0;
  While I < ByteCount Do
  Begin
    mCharSize := TStreamReader_GetGBKCharSize(Bytes[I]);
    Inc(Result);
    Inc(I, mCharSize);
  End;
End;

Function TStreamReader_GetPosition(Const Self: PStream): TSize;
Begin
  Result := PStreamReader(Self)^.FPosition;
End;

Procedure TStreamReader_SetPosition(Const Self: PStream; Value: TSize);
Var
  mSelf: PStreamReader;
  mBytes: Array[0..3] Of Byte;
Begin
  mSelf := PStreamReader(Self);
  If mSelf = nil Then
    Exit;

  If Value < mSelf^.FCharBytePositionCount Then
  Begin
    Seek(mSelf^.FFile, mSelf^.FCharBytePositions[Value]);
    mSelf^.FPosition := Value;
    mSelf^.FEof := False;
    Exit;
  End;

  mSelf^.FEof := False;
  While mSelf^.FPosition < Value Do
  Begin
    If TStreamReader_ReadChar(mSelf, @mBytes[0], SizeOf(mBytes)) <= 0 Then
      Break;
  End;
End;

Procedure TStreamReader_Create(Var Self: PStreamReader; Filename: String;
  Encoding: TEncodingKind); Overload;
Var
  mInfo: TEncodingInfo;
  mHasBom: Boolean;
Begin
  If Encoding <> TChar_GetGlobalEncoding Then
    Raise EConvertError.CreateFmt(
      'Stream encoding (%d) does not match the global encoding (%d).',
      [Ord(Encoding), Ord(TChar_GetGlobalEncoding)]);

  mInfo.Kind := Encoding;
  mInfo.BOMSize := 0;
  mHasBom := TStreamReader_DetectEncoding(Filename, mInfo);
  If mHasBom And (mInfo.BOMSize > 0) And (mInfo.Kind <> Encoding) Then
    Raise EConvertError.CreateFmt(
      'File encoding (%s) does not match the global encoding (%s).',
      [TStreamReader_GetEncodingName(mInfo.Kind),
       TStreamReader_GetEncodingName(Encoding)]);

  New(Self);

  Self^.FEncoding := Encoding;
  Self^.Parent.Encoding := Encoding;

  { Open file for reading }
  AssignFile(Self^.FFile, Filename);
  Reset(Self^.FFile, SizeOf(Byte));

  { Skip a BOM only when it matches the selected encoding. }
  Self^.FByteStart := 0;
  If mHasBom And (Encoding = mInfo.Kind) Then
  Begin
    Self^.FByteStart := mInfo.BOMSize;
    Seek(Self^.FFile, Self^.FByteStart);
  End;

  Self^.FPosition := 0;
  Self^.FEof := False;
  SetLength(Self^.FCharBytePositions, 1);
  Self^.FCharBytePositions[0] := Self^.FByteStart;
  Self^.FCharBytePositionCount := 1;
  Self^.Parent.VMT := @mTStreamReader_VMT;
End;

Procedure TStreamReader_Create(Var Self: PStreamReader; Filename: String); Overload;
Begin
  TStreamReader_Create(Self, Filename, TChar_GetGlobalEncoding);
End;

{ Count total characters in file }
Function TStreamReader_GetLength(Const Self: PStream): TSize;
Var
  mSelf: PStreamReader;
  mOriginalBytePosition, mOriginalCharacterPosition: TSize;
  mOriginalEof: Boolean;
  mBytes: Array[0..3] Of Byte;
Begin
  mSelf := PStreamReader(Self);
  Result := 0;
  mOriginalBytePosition := FilePos(mSelf^.FFile);
  mOriginalCharacterPosition := mSelf^.FPosition;
  mOriginalEof := mSelf^.FEof;
  Seek(mSelf^.FFile, mSelf^.FByteStart);
  mSelf^.FPosition := 0;
  mSelf^.FEof := False;
  While TStreamReader_ReadChar(mSelf, @mBytes[0], SizeOf(mBytes)) > 0 Do
  Begin
    Inc(Result);
  End;
  Seek(mSelf^.FFile, mOriginalBytePosition);
  mSelf^.FPosition := mOriginalCharacterPosition;
  mSelf^.FEof := mOriginalEof;
End;

Function TStreamReader_IsEof(Const Self: PStream): Boolean;
Begin
  Result := PStreamReader(Self)^.FEof Or EOF(PStreamReader(Self)^.FFile);
End;

Function TStreamReader_Read(Const Self: PStream; Var Data; Const Length: TSize; Var Size: TSize): TSize;
Var
  mSelf: PStreamReader;
  mBuffer: Array Of Byte;
  mBytesRead: Integer;
Begin
  mSelf := PStreamReader(Self);
  Result := 0;
  Size := 0;
  If Length = 0 Then
    Exit;

  SetLength(mBuffer, Length * 4);
  While Result < Length Do
  Begin
    mBytesRead := TStreamReader_ReadChar(mSelf, @mBuffer[Size], 4);
    If mBytesRead <= 0 Then
      Break;
    Inc(Size, mBytesRead);
    Inc(Result);
  End;

  If Size > 0 Then
    Move(mBuffer[0], Data, Size);
End;

Function TStreamReader_Write(Const Self: PStream; Var Data; Const Length: TSize; Var Size: TSize): TSize;
{$IFDEF WIN64}
Var
  mResult: Integer;
{$ENDIF}
Begin
  {$IFDEF CPU64}
  BlockWrite(PStreamReader(Self)^.FFile, Data, Int64(Length), Int64(Result));
  {$ELSE}
  {$IFDEF WIN64}
  BlockWrite(PStreamReader(Self)^.FFile, Data, Integer(Length), mResult);
  Result := mResult;
  {$ELSE}
  BlockWrite(PStreamReader(Self)^.FFile, Data, Length, Result);
  {$ENDIF}
  {$ENDIF}
  Size := Result;
End;

Function TStreamReader_Forward(Const Self: PStream; Offset: TSize): Boolean;
Begin
  { Skip Offset characters }
  TStreamReader_SetPosition(Self, TStreamReader_GetPosition(Self) + Offset);
  Result := True;
End;

Function TStreamReader_Rewind(Const Self: PStream; Offset: TSize): Boolean;
Var
  mPosition: TSize;
Begin
  { Move back Offset characters }
  mPosition := TStreamReader_GetPosition(Self);
  If Offset > mPosition Then
    TStreamReader_SetPosition(Self, 0)
  Else
    TStreamReader_SetPosition(Self, mPosition - Offset);
  Result := True;
End;

{ ============================================================
  Initialization
============================================================ }

Initialization

  { Initialize VMT }
  mTStreamReader_VMT.Destroy := TStreamReader_Destroy;
  mTStreamReader_VMT.GetLength := TStreamReader_GetLength;
  mTStreamReader_VMT.GetPosition := TStreamReader_GetPosition;
  mTStreamReader_VMT.SetPosition := TStreamReader_SetPosition;
  mTStreamReader_VMT.Forward := TStreamReader_Forward;
  mTStreamReader_VMT.Rewind := TStreamReader_Rewind;
  mTStreamReader_VMT.IsEof := TStreamReader_IsEof;
  mTStreamReader_VMT.Read := TStreamReader_Read;
  mTStreamReader_VMT.Write := TStreamReader_Write;

Finalization

End.
