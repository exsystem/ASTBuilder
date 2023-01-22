Unit Trie;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  TypeDef;

Type
  PNode = ^TNode;

  TNode = Record
    Next: Array[Low(Byte) .. High(Byte)] Of PNode;
    Leaf: Boolean;
    Data: Pointer;
  End;

  PTrie = ^TTrie;

  TTrie = Record
    FElemSize: TSize;
    Root: PNode;
  End;

Function TTrie_Create(Const ElementSize: TSize): PTrie;
Procedure TTrie_Clear(Self: PTrie);
Function TTrie_Get(Self: PTrie; Const Key: String): Pointer;
Procedure TTrie_Set(Self: PTrie; Const Key: String; Value: Pointer);
Procedure TTrie_Erase(Self: PTrie; Const Key: String);
Procedure TTrie_Destroy(Self: PTrie);
Function TTrie_CreateNode(): PNode;
Function TTrie_Empty(Root: PNode): Boolean;
Function TTrie_Delete(Self: PTrie; Root: PNode; Key: String; Depth: TSize): PNode;
Procedure TTrie_DoClear(Root: PNode);

Implementation

Function TTrie_Create(Const ElementSize: TSize): PTrie;
Begin
  New(Result);
  Result.FElemSize := ElementSize;
  Result.Root := TTrie_CreateNode();
End;

Procedure TTrie_Clear(Self: PTrie);
Var
  I: TSize;
Begin
  For I := Low(Byte) To High(Byte) Do
  Begin
    TTrie_DoClear(Self.Root.Next[I]);
  End;
End;

Function TTrie_Get(Self: PTrie; Const Key: String): Pointer;
Var
  mNode: PNode;
  mKey: PByte;
  I: TSize;
Begin
  mNode := Self.Root;
  mKey := PByte(@Key[Low(Key)]);
  For I := 0 To Length(Key) * SizeOf(Char) - 1 Do
  Begin
    mNode := mNode.Next[mKey[I]];
    If mNode = nil Then
    Begin
      Result := nil;
      Exit;
    End;
  End;
  Result := mNode.Data;
End;

Procedure TTrie_Set(Self: PTrie; Const Key: String; Value: Pointer);
Var
  mNode: PNode;
  mKey: PByte;
  I: TSize;
Begin
  mNode := Self.Root;
  mKey := PByte(@Key[Low(Key)]);
  For I := 0 To Length(Key) * SizeOf(Char) - 1 Do
  Begin
    If mNode.Next[mKey[I]] = nil Then
    Begin
      mNode.Next[mKey[I]] := TTrie_CreateNode();
      mNode.Next[mKey[I]].Data := nil;
    End;
    mNode := mNode.Next[mKey[I]];
  End;
  If mNode.Data <> nil Then
  Begin
    FreeMem(mNode.Data, Self.FElemSize);
  End;
  GetMem(mNode.Data, Self.FElemSize);
  Move(Value^, mNode.Data^, Self.FElemSize);
  mNode.Leaf := True;
End;

Procedure TTrie_Erase(Self: PTrie; Const Key: String);
Begin
  TTrie_Delete(Self, Self.Root, Key, 0);
End;

Procedure TTrie_Destroy(Self: PTrie);
Begin
  TTrie_Clear(Self);
  Dispose(Self.Root);
  Dispose(Self);
End;

Function TTrie_CreateNode(): PNode;
Var
  I: TSize;
Begin
  New(Result);
  For I := Low(Byte) To High(Byte) Do
  Begin
    Result.Next[I] := nil;
  End;
End;

Function TTrie_Delete(Self: PTrie; Root: PNode; Key: String; Depth: TSize): PNode;
Var
  mKey: PByte;
Begin
  mKey := PByte(@Key[Low(Key)]);
  If Root = nil Then
  Begin
    Result := nil;
    Exit;
  End;

  If Depth = Succ(Length(Key) * SizeOf(Char)) Then
  Begin
    Root.Leaf := False;
    If TTrie_Empty(Root) Then
    Begin
      FreeMem(Root.Data, Self.FElemSize);
      Dispose(Root);
      Root := nil;
    End;
    Result := Root;
    Exit;
  End;

  Root.Next[mKey[Depth]] := TTrie_Delete(Self, Root.Next[mKey[Depth]], Key, Succ(Depth));

  If TTrie_Empty(Root) And (Not Root.Leaf) Then
  Begin
    FreeMem(Root.Data, Self.FElemSize);
    Dispose(Root);
    Root := nil;
  End;
  Result := Root;
End;

Function TTrie_Empty(Root: PNode): Boolean;
Var
  I: TSize;
Begin
  For I := Low(Byte) To High(Byte) Do
  Begin
    If Root.Next[I] <> nil Then
    Begin
      Result := False;
      Exit;
    End;
  End;
  Result := True;
End;

Procedure TTrie_DoClear(Root: PNode);
Var
  I: TSize;
Begin
  If Root = nil Then
  Begin
    Exit;
  End;
  For i := Low(Byte) To High(Byte) Do
  Begin
    TTrie_DoClear(Root.Next[I]);
  End;
  FreeMem(Root.Data);
  Dispose(Root);
End;

End.
