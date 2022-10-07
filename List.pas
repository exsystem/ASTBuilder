Unit List;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  TypeDef;

Type
  PList = ^TList;

  TList = Record
    FElemSize: TSize;
    FList: Array Of Byte;
    FCapacity: TSize;
    Size: TSize;
  End;

Function TList_Create(Const ElementSize: TSize; Const Capacity: TSize): PList;
Function TList_IsEmpty(Self: PList): Boolean;
Procedure TList_Clear(Self: PList);
Function TList_Get(Self: PList; Const Index: TSize): Pointer;
Procedure TList_Set(Self: PList; Const Index: TSize; Value: Pointer);
Procedure TList_PushBack(Self: PList; Element: Pointer);
Procedure TList_Erase(Self: PList; Index: TSize); // todo: iterator??
Procedure TList_Destroy(Self: PList);

Implementation

Function TList_Create(Const ElementSize: TSize; Const Capacity: TSize): PList;
Begin
  New(Result);
  Result.FElemSize := ElementSize;
  SetLength(Result.FList, Capacity * ElementSize);
  Result.Size := 0;
End;

Function TList_IsEmpty(Self: PList): Boolean;
Begin
  Result := Self.Size = 0;
End;

Procedure TList_Clear(Self: PList);
Begin
  Self.Size := 0;
End;

Function TList_Get(Self: PList; Const Index: TSize): Pointer;
Begin
  Result := @Self.FList[Index * Self.FElemSize];
End;

Procedure TList_Set(Self: PList; Const Index: TSize; Value: Pointer);
Begin
  Move(Value^, Self.FList[Index], Self.FElemSize);
End;

Procedure TList_PushBack(Self: PList; Element: Pointer);
Begin
  If Self.Size * Self.FElemSize = Length(Self.FList) Then
  Begin
    SetLength(Self.FList, Self.Size * Self.FElemSize * 2);
  End;
  Move(Element^, Self.FList[Self.Size * Self.FElemSize], Self.FElemSize);
  Inc(Self.Size);
End;

Procedure TList_Erase(Self: PList; Index: TSize); // todo: iterator??
Begin
  Move(Self.FList[Succ(Index) * Self.FElemSize], Self.FList[Index * Self.FElemSize],
    (Self.Size - Succ(Index)) * Self.FElemSize);
  Dec(Self.Size);
End;

Procedure TList_Destroy(Self: PList);
Begin
  Dispose(Self);
End;

End.
