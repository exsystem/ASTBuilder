Unit List;

{$I define.inc}

Interface

Uses
  TypeDef;

Type
  PList = ^TList;

  TList = Record
    FElemSize: TSize;
    FList: {$IFDEF VINTAGE}PChar{$ELSE}PByte{$ENDIF};
    FCapacity: TSize;
    Size: TSize;
  End;

  PPList = ^PList;

Function TList_Create(ElementSize: TSize; Capacity: TSize): PList;
Procedure TList_Grow(Self: PList);
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

Uses
  SysUtils;

Function TList_Create(ElementSize: TSize; Capacity: TSize): PList;
Begin
  New(Result);
  GetMem(Result^.FList, Capacity * ElementSize);
  Result^.FElemSize := ElementSize;
  Result^.FCapacity := Capacity;
  Result^.Size := 0;
End;

Procedure TList_Grow(Self: PList);
Begin
  If Self^.Size = Self^.FCapacity Then
  Begin
    {$IFDEF VINTAGE}
    Self^.FList := ReallocMem(Self^.FList, Self^.FCapacity * Self^.FElemSize, Self^.FCapacity * 2 * Self^.FElemSize);
    {$ELSE}
    ReallocMem(Self^.FList, Self^.FCapacity * 2 * Self^.FElemSize);
    {$ENDIF}
    Self^.FCapacity := Self^.Size * 2;
  End;
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
  Result := Self^.FList;
  Inc(TSize(Result), Index * Self^.FElemSize);
End;

Procedure TList_Set(Self: PList; Const Index: TSize; Value: Pointer);
Var
  P: Pointer;
Begin
  P := Self^.FList;
  Inc(TSize(P), Index * Self^.FElemSize);
  Move(Value^, P^, Self^.FElemSize);
End;

Procedure TList_PushBack(Self: PList; Element: Pointer);
Var
  P: Pointer;
Begin
  TList_Grow(Self);
  P := Self^.FList;
  Inc(TSize(P), Self^.Size * Self^.FElemSize);
  Move(Element^, P^, Self^.FElemSize);
  Inc(Self^.Size);
End;

Procedure TList_PopBack(Self: PList);
Begin
  Dec(Self^.Size);
End;

Function TList_EmplaceBack(Self: PList): Pointer;
Begin
  TList_Grow(Self);
  Result := Self^.FList;
  Inc(TSize(Result), Self^.Size * Self^.FElemSize);
  Inc(Self^.Size);
End;

Procedure TList_Erase(Self: PList; Index: TSize); { todo: iterator?? }
Var
  mSrc, mDst: Pointer;
Begin
  If Index <> Self^.Size - 1 Then
  Begin
    mDst := Self^.FList;
    Inc(TSize(mDst), Index * Self^.FElemSize);
    mSrc := mDst;
    Inc(TSize(mSrc), Self^.FElemSize);
    Move(mSrc^, mDst^, (Self^.Size - Succ(Index)) * Self^.FElemSize);
  End;
  Dec(Self^.Size);
End;

Function TList_Back(Self: PList): Pointer;
Begin
  Result := TList_Get(Self, Self^.Size - 1);
End;

Procedure TList_Destroy(Self: PList);
Begin
  FreeMem(Self^.FList, Self^.FCapacity * Self^.FElemSize);
  Dispose(Self);
End;

End.
