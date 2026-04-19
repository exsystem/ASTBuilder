{ Stream Reader Unit for handling files with different encodings }
{ Modern stream reader pattern - similar to Java/C# approach }

Unit StreamReader;

{$I define.inc}

Interface

Uses
  SysUtils, TypeDef, Stream;

Type
  { TEncodingKind - enumeration of supported encodings }
  TEncodingKind = (
    ekASCII,
    ekUTF8,
    ekUTF16LE,      { UTF-16 Little Endian }
    ekUTF16BE,      { UTF-16 Big Endian }
    ekGBK           { Chinese GBK encoding }
    );

  PStreamReader = ^TStreamReader;

  TStreamReader = Record
    Parent: TStream;                { Base stream interface }
    FFile: File Of Byte;
    FEncoding: TEncodingKind;       { Current encoding }
    FEof: Boolean;
    FPosition: TSize; { Position in characters }
  End;

  { Encoding detection result }
  TEncodingInfo = Record
    Kind: TEncodingKind;
    BOMSize: TSize;  { Size of Byte Order Mark }
  End;

{ ============================================================
  TStreamReader API functions
============================================================ }

Procedure TStreamReader_Create(Var Self: PStreamReader; Filename: String;
  Encoding: TEncodingKind = ekUTF8);
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

{ ============================================================
  Internal helper functions
============================================================ }

{ Get number of bytes in a UTF-8 character based on first byte }
Function TStreamReader_GetUTF8CharSize(FirstByte: Byte): TSize;
Begin
  If (FirstByte And $80) = $00 Then
    Result := 1   { ASCII: 0xxxxxxx }
  Else If (FirstByte And $E0) = $C0 Then
    Result := 2   { 2-byte UTF-8: 110xxxxx 10xxxxxx }
  Else If (FirstByte And $F0) = $E0 Then
    Result := 3   { 3-byte UTF-8: 1110xxxx 10xxxxxx 10xxxxxx }
  Else If (FirstByte And $F8) = $F0 Then
    Result := 4   { 4-byte UTF-8: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx }
  Else
    Result := 1;  { Invalid UTF-8, treat as 1 byte }
End;

{ Get number of bytes in a GBK character based on first byte }
Function TStreamReader_GetGBKCharSize(FirstByte: Byte): TSize;
Begin
  If (FirstByte And $80) = $00 Then
    Result := 1   { ASCII: 0xxxxxxx }
  Else If (FirstByte And $80) <> $00 Then
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
      If (mBytes[0] = $EF) And (mBytes[1] = $BB) And (mBytes[2] = $BF) Then
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
End;

Function TStreamReader_ReadChar(Const Self: PStreamReader; Const Ch: PByte;
  MaxSize: TSize): Integer;
Var
  mByteBuf: Array[0..3] Of Byte;
  mBytesRead, I, mCharSize: Integer;
Begin
  Result := 0;

  If Self.FEof Then
    Exit;

  { Read first byte }
  BlockRead(Self.FFile, mByteBuf[0], 1, mBytesRead);
  If mBytesRead = 0 Then
  Begin
    Self.FEof := True;
    Exit;
  End;

  { Determine character size based on encoding }
  Case Self.FEncoding Of
    ekASCII:
      mCharSize := 1;
    ekUTF8:
      mCharSize := TStreamReader_GetUTF8CharSize(mByteBuf[0]);
    ekGBK:
      mCharSize := TStreamReader_GetGBKCharSize(mByteBuf[0]);
    ekUTF16LE, ekUTF16BE:
      mCharSize := 2;  { UTF-16 uses 2 bytes minimum }
    Else
      mCharSize := 1;
  End;

  { Read remaining bytes if needed }
  For I := 1 To mCharSize - 1 Do
  Begin
    BlockRead(Self.FFile, mByteBuf[I], 1, mBytesRead);
    If mBytesRead = 0 Then
    Begin
      Self.FEof := True;
      Exit;
    End;
  End;

  { Return bytes as raw character data (raw byte array) }
  If mCharSize <= MaxSize Then
  Begin
    Move(mByteBuf[0], Ch^, mCharSize);
    Result := mCharSize;
  End
  Else
  Begin
    { Buffer too small }
    Result := -1;
  End;
End;

{ Read a character and return as string (raw bytes) }
Function TStreamReader_ReadCharToString(Const Self: PStreamReader;
  Out Ch: String): Boolean;
Var
  mBuf: Array[0..3] Of Byte;
  mBytesRead, I, mCharSize: Integer;
Begin
  Result := False;

  If Self.FEof Then
    Exit;

  BlockRead(Self.FFile, mBuf[0], 1, mBytesRead);
  If mBytesRead = 0 Then
  Begin
    Self.FEof := True;
    Exit;
  End;

  Case Self.FEncoding Of
    ekASCII: mCharSize := 1;
    ekUTF8: mCharSize := TStreamReader_GetUTF8CharSize(mBuf[0]);
    ekGBK: mCharSize := TStreamReader_GetGBKCharSize(mBuf[0]);
    ekUTF16LE, ekUTF16BE: mCharSize := 2;
    Else
      mCharSize := 1;
  End;

  For I := 1 To mCharSize - 1 Do
  Begin
    BlockRead(Self.FFile, mBuf[I], 1, mBytesRead);
    If mBytesRead = 0 Then
    Begin
      Self.FEof := True;
      Exit;
    End;
  End;

  SetLength(Ch, mCharSize);
  Move(mBuf[0], Ch[1], mCharSize);
  Result := True;
End;

Function TStreamReader_ReadLine(Const Self: PStreamReader; Out Line: String): Boolean;
Var
  mBytes: Array Of Byte;  { Dynamic byte array }
  mByteCount, mByteCap: TSize;
  mBytesRead: Integer;
  mByteData: Array[0..3] Of Byte;
  mLineEndFound: Boolean;
Begin
  Result := False;
  Line := '';

  If Self.FEof Then
    Exit;

  mByteCap := 256;
  SetLength(mBytes, mByteCap);
  mByteCount := 0;

  mLineEndFound := False;

  While Not mLineEndFound Do
  Begin
    { Read first byte }
    BlockRead(Self.FFile, mByteData[0], 1, mBytesRead);
    If mBytesRead = 0 Then
      Break;

    { Determine character size based on encoding }
    Case Self.FEncoding Of
      ekASCII: mBytesRead := 1;
      ekGBK: mBytesRead := TStreamReader_GetGBKCharSize(mByteData[0]);
      ekUTF16LE, ekUTF16BE: mBytesRead := 2;
      ekUTF8: mBytesRead := TStreamReader_GetUTF8CharSize(mByteData[0]);
      Else
        mBytesRead := 1;
    End;

    { Read remaining bytes if needed }
    If mBytesRead > 1 Then
      BlockRead(Self.FFile, mByteData[1], Pred(mBytesRead), mBytesRead);

    Inc(mBytesRead);

    { Check for line endings (LF = 0x0A, CR = 0x0D) }
    If (mByteData[0] = $0A) Or (mByteData[0] = $0D) Then
    Begin
      mLineEndFound := True;
      { Skip LF if it comes after CR (CRLF handling) }
      If (mByteData[0] = $0D) And (mBytesRead = 1) Then
      Begin
        { Peek at next byte without consuming }
        If Not EOF(Self.FFile) Then
        Begin
          BlockRead(Self.FFile, mByteData[0], 1, mBytesRead);
          If (mBytesRead = 1) And (mByteData[0] = $0A) Then
          Begin
            { CRLF - skip the LF too }
          End
          Else
          Begin
            { Not CRLF, put byte back (not possible with TFile, so we just continue) }
          End;
        End;
      End;
    End
    Else If mByteData[0] = $0A Then
    Begin
      mLineEndFound := True;
    End;

    If Not mLineEndFound Then
    Begin
      { Buffer grow if needed }
      If mByteCount + mBytesRead > mByteCap Then
      Begin
        Inc(mByteCap, 256);
        SetLength(mBytes, mByteCap);
      End;

      { Copy raw bytes to buffer }
      Move(mByteData[0], mBytes[mByteCount], mBytesRead);
      Inc(mByteCount, mBytesRead);
    End;
  End;

  { Assign raw bytes to string (AnsiString with $H+) }
  If mByteCount > 0 Then
  Begin
    SetLength(Line, mByteCount);
    Move(mBytes[0], Line[1], mByteCount);
    Result := True;
  End;
End;

Function TStreamReader_ReadAllText(Const Self: PStreamReader; Out Text: String): TSize;
Var
  mBytes: Array Of Byte;  { Dynamic byte array }
  mByteCount, mByteCap: TSize;
  mBytesRead: Integer;
  mByteData: Array[0..3] Of Byte;
Begin
  Result := 0;
  Text := '';

  If Self.FEof Then
    Exit;

  mByteCap := 4096;
  SetLength(mBytes, mByteCap);
  mByteCount := 0;

  While True Do
  Begin
    { Read first byte }
    BlockRead(Self.FFile, mByteData[0], 1, mBytesRead);
    If mBytesRead = 0 Then
      Break;

    { Determine character size based on encoding }
    Case Self.FEncoding Of
      ekASCII: mBytesRead := 1;
      ekGBK: mBytesRead := TStreamReader_GetGBKCharSize(mByteData[0]);
      ekUTF16LE, ekUTF16BE: mBytesRead := 2;
      ekUTF8: mBytesRead := TStreamReader_GetUTF8CharSize(mByteData[0]);
      Else
        mBytesRead := 1;
    End;

    { Read remaining bytes if needed }
    If mBytesRead > 1 Then
      BlockRead(Self.FFile, mByteData[1], Pred(mBytesRead), mBytesRead);

    { Decode to Char based on encoding }
    {
    Var Ch: Char;
    Case Self.FEncoding Of
      ekUTF16LE:
        If mBytesRead >= 2 Then
          Ch := Char(mByteData[0] Or (mByteData[1] Shl 8));
      ekUTF16BE:
        If mBytesRead >= 2 Then
          Ch := Char(mByteData[1] Or (mByteData[0] Shl 8));
      Else
        Ch := Chr(mByteData[0]);
    End;
    }

    Inc(mBytesRead);
    { Buffer grow if needed }
    If mByteCount + mBytesRead > mByteCap Then
    Begin
      Inc(mByteCap, 4096);
      SetLength(mBytes, mByteCap);
    End;

    { Copy raw UTF-8 bytes to buffer }
    Move(mByteData[0], mBytes[mByteCount], mBytesRead);
    Inc(mByteCount, mBytesRead);
    Inc(Result);
  End;

  If mByteCount > 0 Then
  Begin
    { For Free Pascal with $H+, String is AnsiString, so we copy raw bytes }
    Text := '';
    SetLength(Text, mByteCount);
    { Use PAnsiChar to properly handle the byte copy }
    If mByteCount > 0 Then
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
Var
  mSelf: PStreamReader;
  mBytes: Array[0..4095] Of Byte;
  mBytePos, I: TSize;
  mReadCount: Integer;
  mBytesReadResult: Integer;
Begin
  mSelf := PStreamReader(Self);
  If mSelf = nil Then
  Begin
    Result := 0;
    Exit;
  End;

  mBytePos := FilePos(mSelf^.FFile);

  { Count characters from start to current byte position }
  Result := 0;

  If mBytePos > 0 Then
  Begin
    Seek(mSelf^.FFile, 0);

    I := 0;
    While (I < mBytePos) Do
    Begin
      mBytesReadResult := 0;
      If (mBytePos - I) > SizeOf(mBytes) Then
        mReadCount := SizeOf(mBytes)
      Else
        mReadCount := mBytePos - I;
      BlockRead(mSelf^.FFile, mBytes[0], mReadCount, mBytesReadResult);
      If mBytesReadResult = 0 Then
        Break;

      { Count characters in this chunk based on encoding }
      Case mSelf^.FEncoding Of
        ekASCII:
          Result := Result + mBytesReadResult;
        ekUTF16LE, ekUTF16BE:
          { UTF-16: 2 bytes per character }
          Result := Result + (mBytesReadResult Div 2);
        ekUTF8:
          Result := Result + CountUTF8Characters(@mBytes[0], mBytesReadResult);
        ekGBK:
          Result := Result + CountGBKCharacters(@mBytes[0], mBytesReadResult);
      End;

      I := I + mBytesReadResult;
    End;
  End;
End;

Procedure TStreamReader_SetPosition(Const Self: PStream; Value: TSize);
Var
  mSelf: PStreamReader;
  mBytes: Array[0..4095] Of Byte;
  I, mCharSize, mTargetChar: TSize;
  mReadCount: Integer;
  mBytesReadResult: Integer;
Begin
  mSelf := PStreamReader(Self);
  If mSelf = nil Then
    Exit;

  Seek(mSelf^.FFile, 0); { Start from beginning }
  mTargetChar := 0;

  While (mTargetChar < Value) Do
  Begin
    { Read enough bytes for at least one complete character }
    Case mSelf^.FEncoding Of
      ekASCII:
        mReadCount := SizeOf(mBytes);
      ekUTF8:
        mReadCount := SizeOf(mBytes);  { UTF-8 chars are 1-4 bytes }
      ekUTF16LE, ekUTF16BE:
        mReadCount := SizeOf(mBytes) And (Not 1);  { UTF-16 needs even bytes }
      ekGBK:
        mReadCount := SizeOf(mBytes) And (Not 1);  { GBK uses 2 bytes }
      Else
        mReadCount := SizeOf(mBytes);
    End;
    
    { Don't read past end of file }
    If FilePos(mSelf^.FFile) + mReadCount > FileSize(mSelf^.FFile) Then
      mReadCount := FileSize(mSelf^.FFile) - FilePos(mSelf^.FFile);
      
    If mReadCount = 0 Then
      Break;

    BlockRead(mSelf^.FFile, mBytes[0], mReadCount, mBytesReadResult);
    If mBytesReadResult = 0 Then
      Break;

    I := 0;
    While (I < mBytesReadResult) And (mTargetChar < Value) Do
    Begin
      Case mSelf^.FEncoding Of
        ekASCII:
          mCharSize := 1;
        ekUTF16LE, ekUTF16BE:
          mCharSize := 2;
        ekUTF8:
          mCharSize := TStreamReader_GetUTF8CharSize(mBytes[I]);
        ekGBK:
          mCharSize := TStreamReader_GetGBKCharSize(mBytes[I]);
      End;

      Inc(mTargetChar);
      If mTargetChar < Value Then
        Inc(I, mCharSize)
      Else
        Break;
    End;

    If mTargetChar < Value Then
      Continue { Read more }
    Else
    Begin
      { We have enough characters, seek to correct position }
      Seek(mSelf^.FFile, FilePos(mSelf^.FFile) - mBytesReadResult + I);
      Break;
    End;
  End;

  If mTargetChar < Value Then
  Begin
    { Reached EOF before target position }
    Seek(mSelf^.FFile, FileSize(mSelf^.FFile));
  End;
  
  mSelf^.FPosition := mTargetChar;
End;

Procedure TStreamReader_Create(Var Self: PStreamReader; Filename: String;
  Encoding: TEncodingKind = ekUTF8);
Var
  mInfo: TEncodingInfo;
Begin
  New(Self);

  { Detect encoding if ekUTF8 (default) }
  If Encoding = ekUTF8 Then
  Begin
    If TStreamReader_DetectEncoding(Filename, mInfo) Then
      Encoding := mInfo.Kind;
  End;

  Self^.FEncoding := Encoding;

  { Open file for reading }
  AssignFile(Self^.FFile, Filename);
  Reset(Self^.FFile, SizeOf(Byte));

  { Skip BOM if present }
  If Encoding <> ekASCII Then
  Begin
    Case Encoding Of
      ekUTF8:
        If mInfo.BOMSize = 3 Then
          Seek(Self^.FFile, 3);
      ekUTF16LE, ekUTF16BE:
        If mInfo.BOMSize = 2 Then
          Seek(Self^.FFile, 2);
    End;
  End;

  Self^.FPosition := 0;
  Self^.FEof := False;
  Self^.Parent.VMT := @mTStreamReader_VMT;
End;

{ Count total characters in file }
Function CountFileCharacters(Const Self: PStreamReader): TSize;
Var
  mBytes: Array[0..4095] Of Byte;
  mTotalBytes, I: TSize;
  mReadCount: Integer;
  mBytesReadResult: Integer;
Begin
  Result := 0;

  mTotalBytes := FileSize(Self.FFile);

  If mTotalBytes > 0 Then
  Begin
    Seek(Self.FFile, 0);

    I := 0;
    While (I < mTotalBytes) Do
    Begin
      mBytesReadResult := 0;
      If (mTotalBytes - I) > SizeOf(mBytes) Then
        mReadCount := SizeOf(mBytes)
      Else
        mReadCount := mTotalBytes - I;
      BlockRead(Self.FFile, mBytes[0], mReadCount, mBytesReadResult);
      If mBytesReadResult = 0 Then
        Break;

      { Count characters in this chunk based on encoding }
      Case Self.FEncoding Of
        ekASCII:
          Result := Result + mBytesReadResult;
        ekUTF16LE, ekUTF16BE:
          { UTF-16: 2 bytes per character }
          Result := Result + (mBytesReadResult Div 2);
        ekUTF8:
          Result := Result + CountUTF8Characters(@mBytes[0], mBytesReadResult);
        ekGBK:
          Result := Result + CountGBKCharacters(@mBytes[0], mBytesReadResult);
      End;

      I := I + mBytesReadResult;
    End;
  End;
End;

Function TStreamReader_GetLength(Const Self: PStream): TSize;
Var
  mReader: PStreamReader;
Begin
  mReader := PStreamReader(Self);
  If mReader = nil Then
  Begin
    Result := 0;
    Exit;
  End;
  Result := CountFileCharacters(mReader);
End;

Function TStreamReader_IsEof(Const Self: PStream): Boolean;
Begin
  Result := EOF(PStreamReader(Self)^.FFile);
End;

Function TStreamReader_Read(Const Self: PStream; Var Data; Const Length: TSize; Var Size: TSize): TSize;
var
  mSelf: PStreamReader;
  mBuffer: Array[0..4095] Of Byte;
  CharSize: TSize;
  mBytesReadResult: Integer;
Begin
  mSelf := PStreamReader(Self);
  Result := 0;
  Size := 0;
  
  If (Length = 0) Or mSelf^.FEof Then
    Exit;
  
  While (Result < Length) And Not mSelf^.FEof Do
  Begin
    { Read first byte }
    BlockRead(mSelf^.FFile, mBuffer[Size], 1, mBytesReadResult);
    
    If mBytesReadResult = 0 Then
    Begin
      mSelf^.FEof := True;
      Break;
    End;
    
    { Determine character size based on encoding }
    Case mSelf^.FEncoding Of
      ekASCII:
        CharSize := 1;
      ekUTF8:
        CharSize := TStreamReader_GetUTF8CharSize(mBuffer[Size]);
      ekUTF16LE, ekUTF16BE:
        CharSize := 2;
      ekGBK:
        CharSize := TStreamReader_GetGBKCharSize(mBuffer[Size]);
      Else
        CharSize := 1;
    End;
    
    { Read remaining bytes for this character }
    If CharSize > 1 Then
      BlockRead(mSelf^.FFile, mBuffer[Succ(Size)], Pred(CharSize), mBytesReadResult);
    
    { Update index for next character }
    Inc(Size, CharSize);
    Inc(Result);  { One character read }
  End;
  
  { Copy all bytes to output buffer }
  If Size > 0 Then
    Move(mBuffer, Data, Size);
  
  { Update position }
  mSelf^.FPosition := mSelf^.FPosition + Result;
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
Begin
  { Move back Offset characters }
  TStreamReader_SetPosition(Self, TStreamReader_GetPosition(Self) - Offset);
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
