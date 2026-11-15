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
Function TCharStrLen(S: PTChar): TSize;
Function TCharStrToAnsiString(S: PTChar): AnsiString;
Function TCharStrNew(Const Source: PTChar): PTChar; Overload;
Function TCharStrNew(Const Source: AnsiString): PTChar; Overload;
Function TCharStrComp(Const LHS, RHS: PTChar): Integer; Overload;
Function TCharStrComp(Const LHS: PTChar; Const RHS: AnsiString): Integer; Overload;
Function TCharStrCopy(Dest, Source: PTChar): PTChar; Overload;
Function TCharStrCopy(Dest: PTChar; Const Source: AnsiString): PTChar; Overload;
Function TCharStrCat(Dest, Source: PTChar): PTChar; Overload;
Function TCharStrCat(Dest: PTChar; Const Source: AnsiString): PTChar; Overload;
Function CreateStr(Len: TSize): PTChar;
Function ReallocStr(S: PTChar; Len: TSize): PTChar;
Procedure FreeStr(S: PTChar);
Function SubStr(S: PTChar; FromIndex: TSize; Len: TSize): PTChar;

Implementation

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

Function TCharStrLen(S: PTChar): TSize;
Var
  mByte: PByte;
Begin
  Result := 0;
  If S = nil Then
    Exit;
  mByte := PByte(S);
  While mByte^ <> 0 Do
  Begin
    Inc(Result);
    Inc(mByte);
  End;
End;

Function TCharStrToAnsiString(S: PTChar): AnsiString;
Var
  mLength: TSize;
Begin
  mLength := TCharStrLen(S);
  SetLength(Result, mLength);
  If mLength > 0 Then
    Move(S^, Result[1], mLength);
End;

Function TCharStrNew(Const Source: PTChar): PTChar;
Var
  mLength: TSize;
Begin
  If Source = nil Then
  Begin
    Result := nil;
    Exit;
  End;
  mLength := TCharStrLen(Source);
  Result := CreateStr(mLength);
  If mLength > 0 Then
    Move(Source^, Result^, mLength);
End;

Function TCharStrNew(Const Source: AnsiString): PTChar;
Var
  mLength: TSize;
Begin
  mLength := Length(Source);
  Result := CreateStr(mLength);
  If mLength > 0 Then
    Move(Source[1], Result^, mLength);
End;

Function TCharStrComp(Const LHS, RHS: PTChar): Integer;
Var
  mLeft, mRight: PByte;
Begin
  mLeft := PByte(LHS);
  mRight := PByte(RHS);
  While (mLeft^ = mRight^) And (mLeft^ <> 0) Do
  Begin
    Inc(mLeft);
    Inc(mRight);
  End;
  Result := Integer(mLeft^)-Integer(mRight^);
End;

Function TCharStrComp(Const LHS: PTChar; Const RHS: AnsiString): Integer;
Var
  mRight: PTChar;
Begin
  mRight := TCharStrNew(RHS);
  Result := TCharStrComp(LHS, mRight);
  FreeStr(mRight);
End;

Function TCharStrCopy(Dest, Source: PTChar): PTChar;
Var
  mLength: TSize;
Begin
  Result := Dest;
  mLength := TCharStrLen(Source);
  If mLength > 0 Then
    Move(Source^, Dest^, mLength);
  PByte(Dest)[mLength] := 0;
End;

Function TCharStrCopy(Dest: PTChar; Const Source: AnsiString): PTChar;
Var
  mLength: TSize;
Begin
  Result := Dest;
  mLength := Length(Source);
  If mLength > 0 Then
    Move(Source[1], Dest^, mLength);
  PByte(Dest)[mLength] := 0;
End;

Function TCharStrCat(Dest, Source: PTChar): PTChar;
Var
  mOffset, mLength: TSize;
Begin
  Result := Dest;
  mOffset := TCharStrLen(Dest);
  mLength := TCharStrLen(Source);
  If mLength > 0 Then
    Move(Source^, PByte(Dest)[mOffset], mLength);
  PByte(Dest)[mOffset + mLength] := 0;
End;

Function TCharStrCat(Dest: PTChar; Const Source: AnsiString): PTChar;
Var
  mOffset, mLength: TSize;
Begin
  Result := Dest;
  mOffset := TCharStrLen(Dest);
  mLength := Length(Source);
  If mLength > 0 Then
    Move(Source[1], PByte(Dest)[mOffset], mLength);
  PByte(Dest)[mOffset + mLength] := 0;
End;

Function CreateStr(Len: TSize): PTChar;
Begin
  GetMem(Result, Len + 1);
  FillChar(Result^, Len + 1, 0);
End;

Function ReallocStr(S: PTChar; Len: TSize): PTChar;
Var
  mLength: TSize;
Begin
  Result := CreateStr(Len);
  mLength := TCharStrLen(S);
  If mLength > Len Then
    mLength := Len;
  If mLength > 0 Then
    Move(S^, Result^, mLength);
  FreeStr(S);
End;

Procedure FreeStr(S: PTChar);
Begin
  If S <> nil Then
    FreeMem(S);
End;

Function SubStr(S: PTChar; FromIndex: TSize; Len: TSize): PTChar;
Begin
  Result := CreateStr(Len);
  If Len > 0 Then
    Move(PByte(S)[FromIndex], Result^, Len);
End;

End.
