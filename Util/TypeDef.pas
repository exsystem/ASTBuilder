Unit TypeDef;

{$I define.inc}

Interface

Type
  TEncodingKind = (
    ekASCII,
    ekUTF8,
    ekUTF16LE,
    ekUTF16BE,
    ekGBK
    );

  TChar = packed Record
    Bytes: Byte;
  End;
  PTChar = ^TChar;
  PPTChar = ^PTChar;

  {$IFDEF TPC}
  Cardinal = Word;
  {$ENDIF}

  {$IFDEF CLASSIC}
  UIntPtr = Cardinal;
  PByte = ^Byte;
  PBoolean = ^Boolean;
  {$ENDIF}

  PSize = ^TSize;
  TSize = UIntPtr;

  PCharBufferInfo = ^TCharBufferInfo;
  TCharBufferInfo = packed Record
    Encoding: TEncodingKind;
    ByteLength: TSize;
    Capacity: TSize;
  End;

  { TODO Allocator? }
  TElementDestructor = Procedure(Const Element: Pointer);

  { 0: invalid, aka '' }
  { 1: root node, aka '*' }
  TNonTermRuleId = TSize;
  PNonTermRuleId = ^TNonTermRuleId;

  { 0: undefined, aka '' }
  { 1: EOF }
  TTermRule = TSize;
  PTermRule = ^TTermRule;

Function TChar_Allocate(Const ByteSize: TSize): PTChar;
Function TChar_AllocateEncoded(Const ByteSize: TSize;
  Encoding: TEncodingKind): PTChar;
Procedure TChar_Deallocate(Var Self: PTChar);
Function TChar_GetEncoding(Self: PTChar): TEncodingKind;
Function TChar_GetByteLength(Self: PTChar): TSize;
Procedure TChar_SetByteLength(Self: PTChar; ByteLength: TSize);
Function TChar_GetEncodedSize(Encoding: TEncodingKind; Bytes: PByte;
  AvailableBytes: TSize; Out CharSize: TSize): Boolean;
Function TChar_GetAsciiValue(Encoding: TEncodingKind; Bytes: PByte;
  CharSize: TSize; Out Value: Byte): Boolean;
Function TChar_EncodeAscii(Encoding: TEncodingKind; Value: Byte;
  Bytes: PByte; Out CharSize: TSize): Boolean;

Function TSize_Make(Const Id: TSize): PSize;
Procedure TSize_Destroy(Var Self: PSize);

Function TNonTermRuleId_Make(Const Id: TNonTermRuleId): PNonTermRuleId;
Procedure TNonTermRuleId_Destroy(Var Self: PNonTermRuleId);
Function TTermRule_Make(Const Id: TTermRule): PTermRule;
Procedure TTermRule_Destroy(Var Self: PTermRule);

Implementation

Function TChar_Allocate(Const ByteSize: TSize): PTChar;
Begin
  Result := TChar_AllocateEncoded(ByteSize, ekUTF8);
End;

Function TChar_AllocateEncoded(Const ByteSize: TSize;
  Encoding: TEncodingKind): PTChar;
Var
  mInfo: PCharBufferInfo;
  mData: PByte;
Begin
  If ByteSize = 0 Then
  Begin
    Result := nil;
    Exit;
  End;
  GetMem(mInfo, SizeOf(TCharBufferInfo) + ByteSize);
  mInfo^.Encoding := Encoding;
  mInfo^.ByteLength := ByteSize;
  mInfo^.Capacity := ByteSize;
  mData := PByte(mInfo);
  Inc(mData, SizeOf(TCharBufferInfo));
  Result := PTChar(mData);
End;

Procedure TChar_Deallocate(Var Self: PTChar);
Var
  mInfo: PByte;
Begin
  If Self <> nil Then
  Begin
    mInfo := PByte(Self);
    Dec(mInfo, SizeOf(TCharBufferInfo));
    FreeMem(mInfo);
    Self := nil;
  End;
End;

Function TChar_GetEncoding(Self: PTChar): TEncodingKind;
Var
  mInfo: PByte;
Begin
  mInfo := PByte(Self);
  Dec(mInfo, SizeOf(TCharBufferInfo));
  Result := PCharBufferInfo(mInfo)^.Encoding;
End;

Function TChar_GetByteLength(Self: PTChar): TSize;
Var
  mInfo: PByte;
Begin
  mInfo := PByte(Self);
  Dec(mInfo, SizeOf(TCharBufferInfo));
  Result := PCharBufferInfo(mInfo)^.ByteLength;
End;

Procedure TChar_SetByteLength(Self: PTChar; ByteLength: TSize);
Var
  mInfo: PCharBufferInfo;
  mInfoData: PByte;
Begin
  mInfoData := PByte(Self);
  Dec(mInfoData, SizeOf(TCharBufferInfo));
  mInfo := PCharBufferInfo(mInfoData);
  If ByteLength > mInfo^.Capacity Then
    ByteLength := mInfo^.Capacity;
  mInfo^.ByteLength := ByteLength;
End;

Function TChar_GetAsciiValue(Encoding: TEncodingKind; Bytes: PByte;
  CharSize: TSize; Out Value: Byte): Boolean;
Var
  mCodeUnit: Word;
Begin
  Result := False;
  If (Bytes = nil) Or (CharSize = 0) Then
    Exit;
  If Encoding In [ekUTF16LE, ekUTF16BE] Then
  Begin
    If CharSize <> 2 Then
      Exit;
    If Encoding = ekUTF16LE Then
      mCodeUnit := Bytes[0] Or (Bytes[1] Shl 8)
    Else
      mCodeUnit := (Bytes[0] Shl 8) Or Bytes[1];
    If mCodeUnit > $7F Then
      Exit;
    Value := Byte(mCodeUnit);
  End
  Else
  Begin
    If (CharSize <> 1) Or (Bytes^ > $7F) Then
      Exit;
    Value := Bytes^;
  End;
  Result := True;
End;

Function TChar_EncodeAscii(Encoding: TEncodingKind; Value: Byte;
  Bytes: PByte; Out CharSize: TSize): Boolean;
Begin
  Result := False;
  CharSize := 0;
  If (Bytes = nil) Or (Value > $7F) Then
    Exit;
  If Encoding = ekUTF16LE Then
  Begin
    Bytes[0] := Value;
    Bytes[1] := 0;
    CharSize := 2;
  End
  Else If Encoding = ekUTF16BE Then
  Begin
    Bytes[0] := 0;
    Bytes[1] := Value;
    CharSize := 2;
  End
  Else
  Begin
    Bytes^ := Value;
    CharSize := 1;
  End;
  Result := True;
End;

Function TChar_GetEncodedSize(Encoding: TEncodingKind; Bytes: PByte;
  AvailableBytes: TSize; Out CharSize: TSize): Boolean;
Var
  I: TSize;
  mCodeUnit, mNextCodeUnit: Word;
Begin
  Result := False;
  CharSize := 0;
  If (Bytes = nil) Or (AvailableBytes = 0) Then
    Exit;

  Case Encoding Of
    ekASCII:
    Begin
      If Bytes^ > $7F Then
        Exit;
      CharSize := 1;
    End;
    ekUTF8:
    Begin
      If Bytes^ <= $7F Then
        CharSize := 1
      Else If (Bytes^ >= $C2) And (Bytes^ <= $DF) Then
        CharSize := 2
      Else If (Bytes^ >= $E0) And (Bytes^ <= $EF) Then
        CharSize := 3
      Else If (Bytes^ >= $F0) And (Bytes^ <= $F4) Then
        CharSize := 4
      Else
        Exit;
      If AvailableBytes < CharSize Then
        Exit;
      For I := 1 To CharSize - 1 Do
      Begin
        If (Bytes[I] < $80) Or (Bytes[I] > $BF) Then
          Exit;
      End;
      If (CharSize = 3) And
        (((Bytes^ = $E0) And (Bytes[1] < $A0)) Or
        ((Bytes^ = $ED) And (Bytes[1] >= $A0))) Then
        Exit;
      If (CharSize = 4) And
        (((Bytes^ = $F0) And (Bytes[1] < $90)) Or
        ((Bytes^ = $F4) And (Bytes[1] > $8F))) Then
        Exit;
    End;
    ekUTF16LE, ekUTF16BE:
    Begin
      If AvailableBytes < 2 Then
        Exit;
      If Encoding = ekUTF16LE Then
        mCodeUnit := Bytes[0] Or (Bytes[1] Shl 8)
      Else
        mCodeUnit := (Bytes[0] Shl 8) Or Bytes[1];
      If (mCodeUnit >= $DC00) And (mCodeUnit <= $DFFF) Then
        Exit;
      CharSize := 2;
      If (mCodeUnit >= $D800) And (mCodeUnit <= $DBFF) Then
      Begin
        If AvailableBytes < 4 Then
          Exit;
        If Encoding = ekUTF16LE Then
          mNextCodeUnit := Bytes[2] Or (Bytes[3] Shl 8)
        Else
          mNextCodeUnit := (Bytes[2] Shl 8) Or Bytes[3];
        If (mNextCodeUnit < $DC00) Or (mNextCodeUnit > $DFFF) Then
          Exit;
        CharSize := 4;
      End;
    End;
    ekGBK:
    Begin
      If Bytes^ <= $7F Then
        CharSize := 1
      Else If (Bytes^ >= $81) And (Bytes^ <= $FE) Then
      Begin
        If AvailableBytes < 2 Then
          Exit;
        If (Bytes[1] < $40) Or (Bytes[1] > $FE) Or
          (Bytes[1] = $7F) Then
          Exit;
        CharSize := 2;
      End
      Else
        Exit;
    End;
  End;
  Result := True;
End;

Function TSize_Make(Const Id: TSize): PSize;
Begin
  New(Result);
  Result^ := Id;
End;

Procedure TSize_Destroy(Var Self: PSize);
Begin
  Dispose(Self);
  Self := nil;
End;

Function TNonTermRuleId_Make(Const Id: TNonTermRuleId): PNonTermRuleId;
Begin
  Result := PNonTermRuleId(TSize_Make(TSize(Id)));
End;

Procedure TNonTermRuleId_Destroy(Var Self: PNonTermRuleId);
Begin
  TSize_Destroy(PSize(Self));
End;

Function TTermRule_Make(Const Id: TTermRule): PTermRule;
Begin
  Result := PTermRule(TSize_Make(TSize(Id)));
End;

Procedure TTermRule_Destroy(Var Self: PTermRule);
Begin
  TSize_Destroy(PSize(Self));
End;

End.
