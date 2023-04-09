Unit List;

{$I define.inc}

Interface

Uses
  TypeDef;

Type
  PList = ^TList;

  TList = Record
    FElemSize: TSize;
    {$IFDEF VINTAGE}
    FList: Array[0..10240] Of Byte;
    {$ELSE}
    FList: Array Of Byte;
    {$ENDIF}
    Size: TSize;
  End;

Function TList_Create(ElementSize: TSize; Capacity: TSize): PList;
Function TList_IsEmpty(Self: PList): Boolean;
Procedure TList_Clear(Self: PList);
Function TList_Get(Self: PList; Const Index: TSize): Pointer;
Procedure TList_Set(Self: PList; Const Index: TSize; Value: Pointer);
Procedure TList_PushBack(Self: PList; Element: Pointer);
Function TList_EmplaceBack(Self: PList): Pointer;
Procedure TList_PopBack(Self: PList);
Procedure TList_Erase(Self: PList; Index: TSize); { todo: iterator?? }
Function TList_Back(Self: PList): Pointer;
Procedure TList_Destroy(Self: PList);

Implementation

Function TList_Create(ElementSize: TSize; Capacity: TSize): PList;
Begin
  New(Result);
  Result^.FElemSize := ElementSize;
  {$IFNDEF VINTAGE}
  SetLength(Result.FList, Capacity * ElementSize);
  {$ENDIF}
  Result^.Size := 0;
End;

Function TList_IsEmpty(Self: PList): Boolean;
Begin
  Result := (Self^.Size = 0);
End;

Procedure TList_Clear(Self: PList);
Begin
  Self^.Size := 0;
End;

Function TList_Get(Self: PList; Const Index: TSize): Pointer;
Begin
  Result := @Self^.FList[Index * Self^.FElemSize];
End;

Procedure TList_Set(Self: PList; Const Index: TSize; Value: Pointer);
Begin
  Move(Value^, Self^.FList[Index * Self^.FElemSize], Self^.FElemSize);
End;

Procedure TList_PushBack(Self: PList; Element: Pointer);
Begin
  {$IFNDEF VINTAGE}
  If Self^.Size * Self^.FElemSize = Length(Self^.FList) Then
  Begin
    SetLength(Self^.FList, Self^.Size * Self^.FElemSize * 2);
  End;
  {$ENDIF}
  Move(Element^, Self^.FList[Self^.Size * Self^.FElemSize], Self^.FElemSize);
  Inc(Self^.Size);
End;

Procedure TList_PopBack(Self: PList);
Begin
  Dec(Self^.Size);
End;

Function TList_EmplaceBack(Self: PList): Pointer;
Begin
  {$IFNDEF VINTAGE}
  If Self^.Size * Self^.FElemSize = Length(Self^.FList) Then
  Begin
    SetLength(Self^.FList, Self^.Size * Self^.FElemSize * 2);
  End;
  {$ENDIF}
  Result := @Self^.FList[Self^.Size * Self^.FElemSize];
  Inc(Self^.Size);
End;

Procedure TList_Erase(Self: PList; Index: TSize); { todo: iterator?? }
Begin
  If Index <> Self^.Size - 1 Then
  Begin
    Move(Self^.FList[Succ(Index) * Self^.FElemSize],
      Self^.FList[Index * Self^.FElemSize],
      (Self^.Size - Succ(Index)) * Self^.FElemSize);
  End;
  Dec(Self^.Size);
End;

Function TList_Back(Self: PList): Pointer;
Begin
  Result := TList_Get(Self, Self^.Size - 1);
End;

Procedure TList_Destroy(Self: PList);
Begin
  Dispose(Self);
End;

End.
