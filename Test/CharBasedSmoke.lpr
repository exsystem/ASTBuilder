Program CharBasedSmoke;

{$MODE DELPHI}

Uses
  TypeDef, StrUtil, NFA;

Var
  mText, mPattern, mNext: PTChar;
  mNfa: PNfa;
Begin
  TChar_SetGlobalEncoding(ekUTF8);
  mText := TCharStrNewEncoded(#$C3#$A9, ekUTF8);
  If (TCharStrLen(mText) <> 1) Or (TCharStrByteLen(mText) <> 2) Then
    Halt(1);
  FreeStr(mText);

  TChar_SetGlobalEncoding(ekUTF16LE);
  mText := TCharStrNewEncoded(#$2D#$4E, ekUTF16LE);
  If (TCharStrLen(mText) <> 1) Or (TCharStrByteLen(mText) <> 2) Then
    Halt(2);
  FreeStr(mText);

  mText := TCharStrNewEncoded(#$41#$00, ekUTF16LE);
  If TCharStrComp(mText, 'A') <> 0 Then
    Halt(9);
  FreeStr(mText);

  mText := TCharStrNew('A');
  If (TCharStrLen(mText) <> 1) Or (TCharStrByteLen(mText) <> 2) Or
    (PByte(mText)[0] <> $41) Or (PByte(mText)[1] <> 0) Then
    Halt(11);
  FreeStr(mText);

  mText := CreateStrEncoded(TCharStrAnsiByteLen('A', ekUTF16LE), ekUTF16LE);
  TCharStrCat(mText, 'A');
  If (TCharStrLen(mText) <> 1) Or (TCharStrByteLen(mText) <> 2) Or
    (PByte(mText)[0] <> $41) Or (PByte(mText)[1] <> 0) Then
    Halt(10);
  FreeStr(mText);

  TChar_SetGlobalEncoding(ekGBK);
  mText := TCharStrNew(#$D6#$D0);
  If (TCharStrLen(mText) <> 1) Or (TCharStrByteLen(mText) <> 2) Then
    Halt(6);
  FreeStr(mText);

  TChar_SetGlobalEncoding(ekUTF16LE);
  mText := TCharStrNewEncoded(#$41#$00#$2D#$4E, ekUTF16LE);
  If (TCharStrLen(mText) <> 2) Or (TCharStrByteLen(mText) <> 4) Then
    Halt(3);
  FreeStr(mText);

  mText := TCharStrNewEncoded(#$3D#$D8#$0D#$DE, ekUTF16LE);
  If (TCharStrLen(mText) <> 1) Or (TCharStrByteLen(mText) <> 4) Then
    Halt(7);
  FreeStr(mText);

  mText := TCharStrNewEncoded(#$41#$00#$00#$00, ekUTF16LE);
  If (TCharStrLen(mText) <> 1) Or (TCharStrByteLen(mText) <> 2) Then
    Halt(4);
  FreeStr(mText);

  TChar_SetGlobalEncoding(ekUTF8);
  mPattern := TCharStrNewEncoded(#$F0#$9F#$8C#$8D, ekUTF8);
  mText := TCharStrNewEncoded(#$F0#$9F#$8C#$8D, ekUTF8);
  TNfa_Create(mNfa);
  TNfa_AddEdgeSized(mNfa, mPattern, 4, ekUTF8, 0, 1);
  TNfa_GetState(mNfa, 1)^.Acceptable := True;
  TNfa_AnyChar(mNfa, 1, 2);
  If Not TNfa_ValidateEncoded(mNfa, mText, 4, ekUTF8, False) Then
    Halt(5);
  TNfa_Destroy(mNfa);
  FreeStr(mPattern);
  FreeStr(mText);

  TChar_SetGlobalEncoding(ekUTF16LE);
  mPattern := TCharStrNewEncoded(#$00#$00, ekUTF16LE);
  mText := TCharStrNewEncoded(#$00#$00#$41#$00, ekUTF16LE);
  TNfa_Create(mNfa);
  TNfa_AddEdgeSized(mNfa, mPattern, 2, ekUTF16LE, 0, 1);
  mNext := mText;
  Inc(mNext, 2);
  TNfa_AddEdgeSized(mNfa, mNext, 2, ekUTF16LE, 1, 2);
  TNfa_GetState(mNfa, 2)^.Acceptable := True;
  If (TCharStrByteLen(mNfa^.Keyword) <> 0) Or
    Not TNfa_ValidateEncoded(mNfa, mText, 4, ekUTF16LE, False) Then
    Halt(8);
  TNfa_Destroy(mNfa);
  FreeStr(mPattern);
  FreeStr(mText);
  TChar_SetGlobalEncoding(ekUTF8);
End.
