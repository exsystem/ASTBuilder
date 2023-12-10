Unit Trie;

{$I define.inc}

Interface

Uses
  TypeDef, STACK;

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
    ElementDestructor: TElementDestructor;
  End;

  PSuffixNodePair = ^TSuffixNodePair;

  TSuffixNodePair = Record
    Suffix: PChar;
    SuffixSize: TSize;
    Node: PNode;
  End;

  PTrieIterator = ^TTrieIterator;

  TTrieIterator = Record
    FTrie: PTrie;
    FNodeStack: PStack; { Of TSuffixNodePair }
    FCurrent: TSuffixNodePair;
  End;

Function TTrie_Create(Const ElementSize: TSize;
  Const ElementDestructor: TElementDestructor): PTrie;
Procedure TTrie_Clear(Self: PTrie);
Function TTrie_Get(Self: PTrie; Const Key: PChar): Pointer;
Procedure TTrie_Set(Self: PTrie; Const Key: PChar; Value: Pointer);
Procedure TTrie_Erase(Self: PTrie; Const Key: PChar);
Procedure TTrie_Destroy(Self: PTrie);
Function TTrie_CreateNode: PNode;
Function TTrie_Empty(Root: PNode): Boolean;
Function TTrie_Delete(Self: PTrie; Root: PNode; Key: PChar; Depth: TSize): PNode;
Function TTrie_Begin(Self: PTrie): PTrieIterator;
Function TTrie_End(Self: PTrie): PTrieIterator;
Procedure TTrie_DoClear(Const Self: PTrie; Root: PNode);

Procedure NodeStackElementDestructor(Const Element: Pointer);
Procedure TTrieIterator_Create(Var Self: PTrieIterator; Const Trie: PTrie);
Procedure TTrieIterator_Destroy(Const Self: PTrieIterator);
Procedure TTrieIterator_Next(Const Self: PTrieIterator);
Function TTrieIterator_Current(Const Self: PTrieIterator): TSuffixNodePair;

{$IFDEF VINTAGE}
Var
  CTrieIterator_End: TTrieIterator;
{$ENDIF}

Implementation

Uses
{$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

Function TTrie_Create(Const ElementSize: TSize;
  Const ElementDestructor: TElementDestructor): PTrie;
Begin
  New(Result);
  Result^.FElemSize := ElementSize;
  Result^.Root := TTrie_CreateNode;
  Result^.Root^.Leaf := False;
  Result^.ElementDestructor := ElementDestructor;
End;

Procedure TTrie_Clear(Self: PTrie);
Var
  I: TSize;
Begin
  For I := Low(Byte) To High(Byte) Do
  Begin
    TTrie_DoClear(Self, Self^.Root^.Next[I]);
  End;
  If Self^.Root^.Leaf And (Self^.Root^.Data <> nil) Then
  Begin
    If @Self^.ElementDestructor <> nil Then
    Begin
      Self^.ElementDestructor(Self^.Root^.Data);
    End;
    FreeMem(Self^.Root^.Data, SizeOf(Self^.FElemSize));
  End;
  Self^.Root^.Leaf := False;
End;

Function TTrie_Get(Self: PTrie; Const Key: PChar): Pointer;
Var
  mNode: PNode;
  mKey: PByte;
  I: TSize;
Begin
  mNode := Self^.Root;
  mKey := PByte(Key);
  I := 0;
  While I < strlen(Key) * SizeOf(Char) Do
  Begin
    mNode := mNode^.Next[mKey^];
    If mNode = nil Then
    Begin
      Result := nil;
      Exit;
    End;
    Inc(mKey, SizeOf(Byte));
    Inc(I, SizeOf(Byte));
  End;
  If mNode^.Leaf Then
  Begin
    Result := mNode^.Data;
    Exit;
  End;
  Result := nil;
End;

Procedure TTrie_Set(Self: PTrie; Const Key: PChar; Value: Pointer);
Var
  mNode: PNode;
  mKey: PByte;
  I: TSize;
Begin
  mNode := Self^.Root;
  mKey := PByte(Key);
  I := 0;
  While I < strlen(Key) * SizeOf(Char) Do
  Begin
    If mNode^.Next[mKey^] = nil Then
    Begin
      mNode^.Next[mKey^] := TTrie_CreateNode;
      mNode^.Next[mKey^]^.Leaf := False;
    End;
    mNode := mNode^.Next[mKey^];
    Inc(mKey, SizeOf(Byte));
    Inc(I, SizeOf(Byte));
  End;

  If mNode^.Leaf And (mNode^.Data <> nil) Then
  Begin
    If @Self^.ElementDestructor <> nil Then
    Begin
      Self^.ElementDestructor(mNode^.Data);
    End;
    FreeMem(mNode^.Data, Self^.FElemSize);
  End;
  mNode^.Leaf := True;
  GetMem(mNode^.Data, Self^.FElemSize);
  Move(Value^, mNode^.Data^, Self^.FElemSize);
End;

Procedure TTrie_Erase(Self: PTrie; Const Key: PChar);
Begin
  TTrie_Delete(Self, Self^.Root, Key, 0);
End;

Procedure TTrie_Destroy(Self: PTrie);
Begin
  TTrie_Clear(Self);
  Dispose(Self^.Root);
  Dispose(Self);
End;

Function TTrie_CreateNode: PNode;
Var
  I: TSize;
Begin
  New(Result);
  For I := Low(Byte) To High(Byte) Do
  Begin
    Result^.Next[I] := nil;
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
    If Root^.Leaf Then
    Begin
      Root^.Leaf := False;
      If Root^.Data <> nil Then
      Begin
        If @Self^.ElementDestructor <> nil Then
        Begin
          Self^.ElementDestructor(Root^.Data);
        End;
        FreeMem(Root^.Data, Self^.FElemSize);
      End;
      If TTrie_Empty(Root) Then
      Begin
        Dispose(Root);
        Root := nil;
      End;
    End;
    Result := Root;
    Exit;
  End;

  Inc(mKey, Depth);
  Root^.Next[mKey^] := TTrie_Delete(Self, Root^.Next[mKey^], Key, Succ(Depth));

  If TTrie_Empty(Root) And (Not Root^.Leaf) Then
  Begin
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
    If Root^.Next[I] <> nil Then
    Begin
      Result := False;
      Exit;
    End;
  End;
  Result := True;
End;

Function TTrie_Begin(Self: PTrie): PTrieIterator;
Begin
  TTrieIterator_Create(Result, Self);
  Result^.FCurrent.Suffix := StrNew('');
  Result^.FCurrent.SuffixSize := 0;
  Result^.FCurrent.Node := Self^.Root;
End;

Function TTrie_End(Self: PTrie): PTrieIterator;
{$IFNDEF VINTAGE}
Const
  CEnd: TTrieIterator = (
    FTrie: nil;
    FNodeStack: nil;
    FCurrent: (
    Suffix: nil;
    SuffixSize: 0;
    Node: nil;
    );
    );
{$ENDIF}
Begin
  Result := @{$IFDEF VINTAGE} CTrieIterator_End {$ELSE} CEnd {$ENDIF};
End;

Procedure TTrie_DoClear(Const Self: PTrie; Root: PNode);
Var
  I: TSize;
Begin
  If Root = nil Then
  Begin
    Exit;
  End;
  For I := Low(Byte) To High(Byte) Do
  Begin
    TTrie_DoClear(Self, Root^.Next[I]);
  End;
  If Root^.Leaf And (Root^.Data <> nil) Then
  Begin
    If @Self^.ElementDestructor <> nil Then
    Begin
      Self^.ElementDestructor(Root^.Data);
    End;
    FreeMem(Root^.Data, SizeOf(Self^.FElemSize));
  End;
  Dispose(Root);
End;

Procedure NodeStackElementDestructor(Const Element: Pointer);
Begin
  FreeStr(TSuffixNodePair(Element^).Suffix);
  Dispose(PSuffixNodePair(Element));
End;

Procedure TTrieIterator_Create(Var Self: PTrieIterator; Const Trie: PTrie);
Begin
  New(Self); { Final }
  Self^.FTrie := Trie;
  Self^.FNodeStack := TStack_Create(SizeOf(TSuffixNodePair), NodeStackElementDestructor);
End;

Procedure TTrieIterator_Destroy(Const Self: PTrieIterator);
Begin
  If Self^.FCurrent.Suffix <> nil Then
  Begin
    FreeStr(Self^.FCurrent.Suffix);
  End;
  TStack_Destroy(Self^.FNodeStack);
End;

Procedure TTrieIterator_Next(Const Self: PTrieIterator);
Var
  I: Byte;
  mPair: PSuffixNodePair;
  mDst: PByte;
Begin
  If Self^.FCurrent.Node = nil Then
  Begin
    Exit;
  End;
  While True Do
  Begin
    For I := High(Byte) Downto Low(Byte) Do
    Begin
      If Self^.FCurrent.Node^.Next[I] <> nil Then
      Begin
        mPair := TStack_Emplace(Self^.FNodeStack);
        If Self^.FCurrent.Suffix = nil Then
        Begin
          GetMem(mPair^.Suffix, SizeOf(Char));
          mPair^.SuffixSize := SizeOf(Char);
          mDst := PByte(mPair^.Suffix);
        End
        Else
        Begin
          mPair^.SuffixSize := Succ(Self^.FCurrent.SuffixSize);
          GetMem(mPair^.Suffix, mPair^.SuffixSize);
          mDst := PByte(mPair^.Suffix);
          Move(Self^.FCurrent.Suffix^, mDst^, Self^.FCurrent.SuffixSize);
          mDst := PByte(mPair^.Suffix);
          Inc(mDst, Self^.FCurrent.SuffixSize);
        End;
        mDst^ := I;
        mPair^.Node := Self^.FCurrent.Node^.Next[I];
      End;
    End;

    FreeStr(Self^.FCurrent.Suffix);
    If TStack_Empty(Self^.FNodeStack) Then
    Begin
      Self^.FCurrent.Suffix := nil;
      Self^.FCurrent.SuffixSize := 0;
      Self^.FCurrent.Node := nil;
      Exit;
    End
    Else
    Begin
      mPair := PSuffixNodePair(TStack_Pop(Self^.FNodeStack));
      Self^.FCurrent := mPair^;
      Dispose(mPair);
      If Self^.FCurrent.Node^.Leaf Then
      Begin
        Exit;
      End;
    End;
  End;
End;

Function TTrieIterator_Current(Const Self: PTrieIterator): TSuffixNodePair;
Begin
  Result := Self^.FCurrent;
End;

{$IFDEF VINTAGE}
Initialization
  CTrieIterator_End.FTrie := nil;
  CTrieIterator_End.FNodeStack := nil;
  CTrieIterator_End.FCurrent.Suffix := nil;  
  CTrieIterator_End.FCurrent.SuffixSize := 0;
  CTrieIterator_End.FCurrent.Node := nil;
{$ENDIF}

End.
