Unit Stack;

{$I define.inc}

Interface

Uses
  TypeDef;

Type
  PNode = ^TNode;

  TNode = Record
    Data: Pointer;
    Next: PNode;
  End;

  PStack = ^TStack;

  TStack = Record
    Top: PNode;
    ElementSize: TSize;
    FElementDestructor: TElementDestructor;
  End;

Function TStack_Create(ElementSize: TSize;
  ElementDestructor: TElementDestructor): PStack;
Procedure TStack_Destroy(Self: PStack);
Function TStack_Empty(Stack: PStack): Boolean;
Function TStack_Emplace(Var Self: PStack): Pointer;
Procedure TStack_Push(Var Self: PStack; Data: Pointer);
Function TStack_Pop(Var Self: PStack): Pointer;
Function TStack_Top(Self: PStack): Pointer;

Implementation

Function TStack_Create(ElementSize: TSize;
  ElementDestructor: TElementDestructor): PStack;
Begin
  New(Result);
  Result^.Top := nil;
  Result^.ElementSize := ElementSize;
  Result^.FElementDestructor := ElementDestructor;
End;

Procedure TStack_Destroy(Self: PStack);
Var
  mElem: Pointer;
Begin
  If @Self^.FElementDestructor = nil Then
  Begin
    While TStack_Pop(Self) <> nil Do
    Begin
      { NOP }
    End;
  End
  Else
  Begin
    While True Do
    Begin
      mElem := TStack_Pop(Self);
      If mElem = nil Then
      Begin
        Break;
      End;
      Self^.FElementDestructor(mElem);
    End;
  End;
  Dispose(Self);
End;

Function TStack_Empty(Stack: PStack): Boolean;
Begin
  Result := Stack^.Top = nil;
End;

Function TStack_Emplace(Var Self: PStack): Pointer;
Var
  P: PNode;
Begin
  New(P);
  GetMem(P^.Data, Self^.ElementSize);
  P^.Next := Self^.Top;
  Self^.Top := P;
  Result := P^.Data;
End;

Procedure TStack_Push(Var Self: PStack; Data: Pointer);
Var
  P: PNode;
Begin
  New(P);
  GetMem(P^.Data, Self^.ElementSize);
  Move(Data^, P^.Data^, Self^.ElementSize);
  P^.Next := Self^.Top;
  Self^.Top := P;
End;

Function TStack_Pop(Var Self: PStack): Pointer;
Var
  P: PNode;
Begin
  If Not TStack_Empty(Self) Then
  Begin
    GetMem(Result, Self^.ElementSize);
    Move(Self^.Top^.Data^, Result^, Self^.ElementSize);
    P := Self^.Top;
    Self^.Top := Self^.Top^.Next;
    FreeMem(P^.Data, Self^.ElementSize);
    Dispose(P);
  End
  Else
  Begin
    Result := nil;
  End;
End;

Function TStack_Top(Self: PStack): Pointer;
Begin
  If Not TStack_Empty(Self) Then
  Begin
    GetMem(Result, Self^.ElementSize);
    Move(Self^.Top^.Data^, Result^, Self^.ElementSize);
  End
  Else
  Begin
    Result := nil;
  End;
End;

End.
