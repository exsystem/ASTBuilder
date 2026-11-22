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
    Bytes: Array[0..0] of Byte;  // 零长度数组，实际使用时动态分配
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
Procedure TChar_Deallocate(Var Self: PTChar);
Function TChar_GetGlobalEncoding: TEncodingKind;
Procedure TChar_SetGlobalEncoding(Encoding: TEncodingKind);
Function TChar_AllocateEncoded(Const ByteSize: TSize; Encoding: TEncodingKind): PTChar;
Procedure TChar_AllocateEncodedDeallocate(Var Self: PTChar; Encoding: TEncodingKind);
Function TChar_GetEncoding(Self: PTChar): TEncodingKind;
Procedure TChar_SetEncoding(Self: PTChar; Encoding: TEncodingKind);
Function TChar_GetByteLength(Self: PTChar): TSize;
Procedure TChar_SetByteLength(Self: PTChar; Length: TSize);
Function TChar_GetEncodedSize(Encoding: TEncodingKind; Bytes: PByte;
  AvailableBytes: TSize; Out CharSize: TSize): Boolean;
Function TChar_GetAsciiValue(Encoding: TEncodingKind; Bytes: PByte;
  CharSize: TSize; Out Value: Byte): Boolean;
Function TChar_EncodeAscii(Encoding: TEncodingKind; Value: Byte;
  Bytes: PByte; Out CharSize: TSize): Boolean;

Function TChar_GetCurrentEncodedSize(Bytes: PByte; AvailableBytes: TSize;
  Out CharSize: TSize): Boolean;
Function TChar_GetCurrentAsciiValue(Bytes: PByte; CharSize: TSize;
  Out Value: Byte): Boolean;
Function TChar_EncodeCurrentAscii(Value: Byte; Bytes: PByte;
  Out CharSize: TSize): Boolean;

Function TSize_Make(Const Id: TSize): PSize;
Procedure TSize_Destroy(Var Self: PSize);

Function TNonTermRuleId_Make(Const Id: TNonTermRuleId): PNonTermRuleId;
Procedure TNonTermRuleId_Destroy(Var Self: PNonTermRuleId);
Function TTermRule_Make(Const Id: TTermRule): PTermRule;
Procedure TTermRule_Destroy(Var Self: PTermRule);

Implementation

// 全局编码配置 - 整个流程使用单一编码
var
  GlobalEncoding: TEncodingKind = ekUTF8;

Function TChar_Allocate(Const ByteSize: TSize): PTChar;
Begin
  if ByteSize = 0 then begin
    Result := nil;
    Exit;
  end;
  // 分配实际需要的字节数，不固定为4字节
  GetMem(Result, ByteSize);
End;

Procedure TChar_Deallocate(Var Self: PTChar);
Begin
  If Self <> nil Then
  Begin
    FreeMem(Self);
    Self := nil;
  End;
End;

Function TChar_GetGlobalEncoding: TEncodingKind;
Begin
  Result := GlobalEncoding;
End;

Procedure TChar_SetGlobalEncoding(Encoding: TEncodingKind);
Begin
  GlobalEncoding := Encoding;
End;

Function TChar_GetEncoding(Self: PTChar): TEncodingKind;
Begin
  Result := TChar_GetGlobalEncoding;
End;

Procedure TChar_SetEncoding(Self: PTChar; Encoding: TEncodingKind);
Begin
  { Compatibility wrapper: encoding is process-wide, not stored per character. }
  TChar_SetGlobalEncoding(Encoding);
End;

Function TChar_GetByteLength(Self: PTChar): TSize;
Var
  I, mCharSize: TSize;
  mEncoding: TEncodingKind;
Begin
  Result := 0;
  if Self = nil then Exit;

  mEncoding := TChar_GetGlobalEncoding;
  I := 0;
  While True Do
  Begin
    If (mEncoding In [ekUTF16LE, ekUTF16BE]) And
      (PByte(Self)[I] = 0) And (PByte(Self)[I + 1] = 0) Then
      Break;
    If Not (mEncoding In [ekUTF16LE, ekUTF16BE]) And
      (PByte(Self)[I] = 0) Then
      Break;
    If Not TChar_GetEncodedSize(mEncoding, @PByte(Self)[I],
      MaxInt - I, mCharSize) Then
      Break;
    Inc(Result, mCharSize);
    Inc(I, mCharSize);
  end;
End;

Procedure TChar_SetByteLength(Self: PTChar; Length: TSize);
Begin
  // 简化实现：TChar 直接存储字节数据，长度由调用者管理
End;

Function TChar_AllocateEncoded(Const ByteSize: TSize; Encoding: TEncodingKind): PTChar;
Begin
  // 编码参数用于未来扩展，当前实现中编码是全局设置的
  Result := TChar_Allocate(ByteSize);
End;

Procedure TChar_AllocateEncodedDeallocate(Var Self: PTChar; Encoding: TEncodingKind);
Begin
  // 编码参数用于未来扩展，当前实现中编码是全局设置的
  TChar_Deallocate(Self);
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

// 当前编码相关的便捷函数（使用全局变量）
Function TChar_GetCurrentEncodedSize(Bytes: PByte; AvailableBytes: TSize;
  Out CharSize: TSize): Boolean;
Begin
  Result := TChar_GetEncodedSize(GlobalEncoding, Bytes, AvailableBytes, CharSize);
End;

Function TChar_GetCurrentAsciiValue(Bytes: PByte; CharSize: TSize;
  Out Value: Byte): Boolean;
Begin
  Result := TChar_GetAsciiValue(GlobalEncoding, Bytes, CharSize, Value);
End;

Function TChar_EncodeCurrentAscii(Value: Byte; Bytes: PByte;
  Out CharSize: TSize): Boolean;
Begin
  Result := TChar_EncodeAscii(GlobalEncoding, Value, Bytes, CharSize);
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
