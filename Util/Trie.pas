Unit Trie;

{$I define.inc}

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
Function TTrie_Get(Self: PTrie; Const Key: PChar): Pointer;
Procedure TTrie_Set(Self: PTrie; Const Key: PChar; Value: Pointer);
Procedure TTrie_Erase(Self: PTrie; Const Key: PChar);
Procedure TTrie_Destroy(Self: PTrie);
Function TTrie_CreateNode(): PNode;
Function TTrie_Empty(Root: PNode): Boolean;
Function TTrie_Delete(Self: PTrie; Root: PNode; Key: PChar; Depth: TSize): PNode;
Procedure TTrie_DoClear(Root: PNode);

Implementation

Uses
{$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF};

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

Function TTrie_Get(Self: PTrie; Const Key: PChar): Pointer;
Var
  mNode: PNode;
  mKey: PByte;
  I: TSize;
Begin
  mNode := Self.Root;
  mKey := PByte(Key);
  I := 0;
  While I < strlen(Key) * SizeOf(Char) do
  begin
    mNode := mNode.Next[mKey^];
    If mNode = nil Then
    Begin
      Result := nil;
      Exit;
    End;
    Inc(mKey, I);
  end;
  Result := mNode.Data;
End;

Procedure TTrie_Set(Self: PTrie; Const Key: PChar; Value: Pointer);
Var
  mNode: PNode;
  mKey: PByte;
  I: TSize;
Begin
  mNode := Self.Root;
  mKey := PByte(Key);
  I := 0;
  While I < strlen(Key) * SizeOf(Char) do
  begin
    If mNode.Next[mKey^] = nil Then
    Begin
      mNode.Next[mKey^] := TTrie_CreateNode();
      mNode.Next[mKey^].Data := nil;
    End;
    mNode := mNode.Next[mKey^];
    Inc(mKey, I);
  end;
  
  If mNode.Data <> nil Then
  Begin
    FreeMem(mNode.Data, Self.FElemSize);
  End;
  GetMem(mNode.Data, Self.FElemSize);
  Move(Value^, mNode.Data^, Self.FElemSize);
  mNode.Leaf := True;
End;

Procedure TTrie_Erase(Self: PTrie; Const Key: PChar);
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

Function TTrie_Delete(Self: PTrie; Root: PNode; Key: PChar; Depth: TSize): PNode;
Var
  mKey: PByte;
Begin
  mKey := PByte(Key);
  If Root = nil Then
  Begin
    Result := nil;
    Exit;
  End;

  If Depth = Succ(StrLen(Key) * SizeOf(Char)) Then
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

  Inc(mKey, Depth);
  Root.Next[mKey^] := TTrie_Delete(Self, Root.Next[mKey^], Key, Succ(Depth));

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
  For I := Low(Byte) To High(Byte) Do
  Begin
    TTrie_DoClear(Root.Next[I]);
  End;
  FreeMem(Root.Data);
  Dispose(Root);
End;

End.
