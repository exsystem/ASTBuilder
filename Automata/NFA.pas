Unit NFA;

Interface

Uses
  List, TypeDef;

Type
  PNfaState = ^TNfaState;

  TNfaState = Record
    Acceptable: Boolean;
    Edges: PList; // of TEdge
  End;

  PNfaEdge = ^TNfaEdge;

  TNfaEdge = Record
    Value: String;
    ToState: TSize;
  End;

  PNfa = ^TNfa;

  TNfa = Record
    StartState: TSize;
    States: PList; // of TNfaState 
  End;

Procedure TNfa_Create(Var Self: PNfa);

Procedure TNfa_Destroy(Self: PNfa);

Function TNfa_GetState(Self: PNfa; StateIndex: TSize): PNfaState;

Procedure TNfa_AddEdge(Self: PNfa; Value: String; Source: TSize; Destination: TSize);

{
  TODO: extend the procedure below to accept mutiple NFAs into one NFA, not only two.
}
Procedure TNfa_Concat(Var Self: PNfa; Nfa: PNfa);

{
  TODO: extend the procedure below to accept mutiple NFAs into one NFA, not only two.
}
Procedure TNfa_Alternative(Var Self: PNfa; Nfa: PNfa);

Procedure TNfa_Multiple(Var Self: PNfa);

Procedure TNfa_Optional(Var Self: PNfa);

Implementation

Procedure TNfa_Create(Var Self: PNfa);
Var
  mState: PNfaState;
Begin
  New(Self);
  Self.States := TList_Create(SizeOf(TNfaState), 5);
  Self.StartState := 0;
  mState := TList_EmplaceBack(Self.States);
  mState.Acceptable := False;
  mState.Edges := TList_Create(SizeOf(TNfaEdge), 1);
End;

Procedure TNfa_Destroy(Self: PNfa);
Var
  I: TSize;
  mState: PNfaState;
Begin
  For I := 0 To Self.States.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Self.States, I));
    TList_Destroy(mState.Edges);
  End;
  TList_Destroy(Self.States);
  Dispose(Self);
End;

Function TNfa_GetState(Self: PNfa; StateIndex: TSize): PNfaState;
Begin
  Result := PNfaState(TList_Get(Self.States, StateIndex));
End;

Procedure TNfa_AddEdge(Self: PNfa; Value: String; Source: TSize; Destination: TSize);
Var
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  mState := PNfaState(TList_Get(Self.States, Source));
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := Value;
  mEdge.ToState := Destination;
  If Destination = Self.States.Size Then
  Begin
    mState := PNfaState(TList_EmplaceBack(Self.States));
    mState.Edges := TList_Create(SizeOf(TNfaEdge), 1);
  End;
End;

{
  For A' := A B;
  1. Connect all acceptable states of A to the start state of B with epsilon edges.
  2. Unmark all acceptable states of A as not acceptable.
  3. Merge B into A with state index increment offset A.Size.
}
Procedure TNfa_Concat(Var Self: PNfa; Nfa: PNfa);
Var
  I, J: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  If Self = nil Then
  Begin
    Self := Nfa;
    Exit;
  End;

  If Nfa = nil Then
  Begin
    Exit;
  End;

  For I := 0 To Self.States.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Self.States, I));
    If mState.Acceptable Then
    Begin
      mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
      mEdge.Value := '';
      mEdge.ToState := Nfa.StartState + Self.States.Size;
      mState.Acceptable := False;
    End;
  End;

  For I := 0 To Nfa.States.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Nfa.States, I));
    If mState.Edges.Size > 0 Then
    Begin
      For J := 0 To mState.Edges.Size - 1 Do
      Begin
        mEdge := PNfaEdge(TList_Get(mState.Edges, J));
        Inc(mEdge.ToState, Self.States.Size);
      End;
    End;
  End;

  For I := 0 To Nfa.States.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Nfa.States, I));
    Move(mState^, PNfaState(TList_EmplaceBack(Self.States))^, SizeOf(TNfaState));
  End;

  TList_Destroy(Nfa.States);
  Dispose(Nfa);
End;

{
  A' := A | B ;
}
Procedure TNfa_Alternative(Var Self: PNfa; Nfa: PNfa);
Var
  I, J: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  For I := 0 To Nfa.States.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Nfa.States, I));
    If mState.Edges.Size > 0 Then
    Begin
      For J := 0 To mState.Edges.Size - 1 Do
      Begin
        mEdge := PNfaEdge(TList_Get(mState.Edges, J));
        Inc(mEdge.ToState, Self.States.Size);
      End;
    End;
    Move(mState^, PNfaState(TList_EmplaceBack(Self.States))^, SizeOf(TNfaState));
  End;

  mState := PNfaState(TList_EmplaceBack(Self.States));
  mState.Acceptable := False;
  mState.Edges := TList_Create(SizeOf(TNfaEdge), 2);
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := '';
  mEdge.ToState := Self.StartState;
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := '';
  mEdge.ToState := Nfa.StartState + (Self.States.Size - 1) - Nfa.States.Size;
  Self.StartState := Self.States.Size - 1;

  mState := PNfaState(TList_EmplaceBack(Self.States));
  mState.Acceptable := True;
  mState.Edges := TList_Create(SizeOf(TNfaEdge), 1);

  For I := 0 To Self.States.Size - 3 Do
  Begin
    mState := PNfaState(TList_Get(Self.States, I));
    If mState.Acceptable Then
    Begin
      mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
      mEdge.Value := '';
      mEdge.ToState := Self.States.Size - 1;
      mState.Acceptable := False;
    End;
  End;

  TList_Destroy(Nfa.States);
  Dispose(Nfa);
End;

{
  A := A * ;
}
Procedure TNfa_Multiple(Var Self: PNfa);
Var
  I: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  mState := PNfaState(TList_EmplaceBack(Self.States));
  mState.Acceptable := False;
  mState.Edges := TList_Create(SizeOf(TNfaEdge), 2);
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := '';
  mEdge.ToState := Self.StartState;
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := '';
  mEdge.ToState := Self.States.Size;
  mState := PNfaState(TList_EmplaceBack(Self.States));
  mState.Acceptable := True;
  mState.Edges := TList_Create(SizeOf(TNfaEdge), 1);

  For I := 0 To Self.States.Size - 3 Do
  Begin
    mState := PNfaState(TList_Get(Self.States, I));
    If mState.Acceptable Then
    Begin
      mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
      mEdge.Value := '';
      mEdge.ToState := Self.StartState;
      mState.Acceptable := False;
      mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
      mEdge.Value := '';
      mEdge.ToState := Self.States.Size - 1;
    End;
  End;

  Self.StartState := Self.States.Size - 2;
End;

{
  A' := A ? ;
}
Procedure TNfa_Optional(Var Self: PNfa);
Var
  I: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  mState := PNfaState(TList_EmplaceBack(Self.States));
  mState.Acceptable := False;
  mState.Edges := TList_Create(SizeOf(TNfaEdge), 2);
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := '';
  mEdge.ToState := Self.StartState;
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := '';
  mEdge.ToState := Self.States.Size;
  mState := PNfaState(TList_EmplaceBack(Self.States));
  mState.Acceptable := True;
  mState.Edges := TList_Create(SizeOf(TNfaEdge), 1);

  For I := 0 To Self.States.Size - 3 Do
  Begin
    mState := PNfaState(TList_Get(Self.States, I));
    If mState.Acceptable Then
    Begin
      mState.Acceptable := False;
      mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
      mEdge.Value := '';
      mEdge.ToState := Self.States.Size - 1;
    End;
  End;

  Self.StartState := Self.States.Size - 2;
End;

End.
