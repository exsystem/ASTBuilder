Unit NFA;

{$I define.inc}

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
    Value: PChar;
    Others: Boolean;
    ToState: TSize;
  End;

  PNfa = ^TNfa;

  TNfa = Record
    StartState: TSize;
    States: PList; // of TNfaState
    FNewStates: PList; // of TSize
    FOldStates: PList; // of TSize
    FAlreadyOn: PList; // of Boolean
    Keyword: PChar;
  End;

Procedure TNfa_Create(Var Self: PNfa);

Procedure TNfa_Destroy(Self: PNfa);

Function TNfa_GetState(Self: PNfa; StateIndex: TSize): PNfaState;

Procedure TNfa_AddEdge(Self: PNfa; Value: PChar; Source: TSize; Destination: TSize);

Procedure TNfa_CombineCharEdge(Self: PNfa; Nfa: PNfa);

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

Procedure TNfa_OneOrMore(Var Self: PNfa);

Procedure TNfa_Not(Var Self: PNfa);

Procedure TNfa_Reset(Var Self: PNfa);

Function TNfa_Move(Var Self: PNfa; Const Ch: Char): Boolean;

Function TNfa_Accepted(Var Self: PNfa): Boolean;

{
  SEE: <<Compilers: Principles, Techniques, and Tools (2nd Edition)>>: Chapter.3.7.2 / Page.156~158
}
Function TNfa_Validate(Var Self: PNfa; Input: PChar): Boolean;

{
  TODO: rename to TNfa_AddEpsilonClosureStates?
}
Procedure TNfa_AddState(Var Self: PNfa; S: TSize);

{
  TODO: rename to TNfa_PrepareOldStatesForNextTurn?
}
Procedure TNfa_ExchangeStates(Var Self: PNfa);

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StringUtils;

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
  Self.Keyword := strnew('');
  Self.FAlreadyOn := nil;
  Self.FOldStates := nil;
  Self.FNewStates := nil;
End;

Procedure TNfa_Destroy(Self: PNfa);
Var
  I, J: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  If Self.FAlreadyOn <> nil Then
  Begin
    Dispose(Self.FAlreadyOn);
    Dispose(Self.FOldStates);
    Dispose(Self.FNewStates);
  End;
  FreeStr(Self.Keyword);
  For I := 0 To Self.States.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Self.States, I));
    If mState.Edges.Size > 0 Then
    Begin
      For J := 0 To mState.Edges.Size - 1 Do
      Begin
        mEdge := PNfaEdge(TList_Get(mState.Edges, J));
        FreeStr(mEdge.Value);
      End;
    End;
    TList_Destroy(mState.Edges);
  End;
  TList_Destroy(Self.States);
  Dispose(Self);
End;

Function TNfa_GetState(Self: PNfa; StateIndex: TSize): PNfaState;
Begin
  Result := PNfaState(TList_Get(Self.States, StateIndex));
End;

Procedure TNfa_AddEdge(Self: PNfa; Value: PChar; Source: TSize; Destination: TSize);
Var
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  mState := PNfaState(TList_Get(Self.States, Source));
  If (Source = Self.States.Size - 1) And (Destination = Self.States.Size) And
    (mState.Edges.Size = 0) Then
  Begin
    Self.Keyword := ReallocStr(Self.Keyword, strlen(Self.Keyword) + strlen(Value));
    strcat(Self.Keyword, Value);
  End
  Else
  Begin
    FreeStr(Self.Keyword);
    Self.Keyword := strnew('');
  End;
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := strnew(Value);
  mEdge.Others := False;
  mEdge.ToState := Destination;
  If Destination = Self.States.Size Then
  Begin
    mState := PNfaState(TList_EmplaceBack(Self.States));
    mState.Edges := TList_Create(SizeOf(TNfaEdge), 1);
  End;
End;

Procedure TNfa_CombineCharEdge(Self: PNfa; Nfa: PNfa);
Var
  mState, mNfaState: PNfaState;
  mEdge, mNfaEdge: PNfaEdge;
  I: TSize;
Begin
  { TODO check if this operation is allowed by Self and Nfa }

  mNfaState := PNfaState(TList_Get(Nfa.States, 0));
  mNfaEdge := PNfaEdge(TList_Get(mNfaState.Edges, 0));

  mState := PNfaState(TList_Get(Self.States, 0));
  For I := 0 To mState.Edges.Size - 1 Do
  Begin
    mEdge := PNfaEdge(TList_Get(mState.Edges, I));
    If strcomp(mEdge.Value, mNfaEdge.Value) = 0 Then
    Begin
      TNfa_Destroy(Nfa);
      Exit;
    End;
  End;

  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := strnew(mNfaEdge.Value);
  mEdge.Others := False;
  mEdge.ToState := 1;

  TNfa_Destroy(Nfa);
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

  If (strcomp(Self.Keyword, '') = 0) Or (strcomp(Nfa.Keyword, '') = 0) Then
  Begin
    FreeStr(Self.Keyword);
    Self.Keyword := strnew('');
  End
  Else
  Begin
    Self.Keyword := ReallocStr(Self.Keyword, strlen(Self.Keyword) + strlen(Nfa.Keyword));
    strcopy(Self.Keyword, Nfa.Keyword);
  End;
  FreeStr(Nfa.Keyword);

  For I := 0 To Self.States.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Self.States, I));
    If mState.Acceptable Then
    Begin
      mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
      mEdge.Value := strnew('');
      mEdge.Others := False;
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
  If (strcomp(Self.Keyword, '') = 0) Xor (strcomp(Nfa.Keyword, '') = 0) Then
  Begin
    Self.Keyword := ReallocStr(Self.Keyword, strlen(Self.Keyword) + strlen(Nfa.Keyword));
    strcat(Self.Keyword, Nfa.Keyword);
  End
  Else
  Begin
    FreeStr(Self.Keyword);
    Self.Keyword := strnew('');
  End;
  FreeStr(Nfa.Keyword);

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
  mEdge.Value := strnew('');
  mEdge.Others := False;
  mEdge.ToState := Self.StartState;
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := strnew('');
  mEdge.Others := False;
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
      mEdge.Value := strnew('');
      mEdge.Others := False;
      mEdge.ToState := Self.States.Size - 1;
      mState.Acceptable := False;
    End;
  End;

  TList_Destroy(Nfa.States);
  Dispose(Nfa);
End;

{
  A := ~A ; // A only contains one char.
}
Procedure TNfa_Not(Var Self: PNfa);
Var
  I: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  FreeStr(Self.Keyword);
  Self.Keyword := strnew('');

  mState := PNfaState(TList_Get(Self.States, 0));
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := strnew('~');
  mEdge.Others := False;
  mEdge.Others := True;
  mEdge.ToState := 2;


  mState := PNfaState(TList_Get(Self.States, 1));
  mState.Acceptable := False;

  mState := PNfaState(TList_EmplaceBack(Self.States));
  mState.Acceptable := True;
  mState.Edges := TList_Create(SizeOf(TNfaEdge), 1);
End;

{
  A := A + ;
}
Procedure TNfa_OneOrMore(Var Self: PNfa);
Var
  I, J: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
  mFlag: Boolean;
Begin
  FreeStr(Self.Keyword);
  Self.Keyword := strnew('');

  For I := 0 To Self.States.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Self.States, I));
    If mState.Acceptable Then
    Begin
      If mState.Edges.Size > 0 Then
      Begin
        mFlag := False;
        For J := 0 To mState.Edges.Size - 1 Do
        Begin
          mEdge := PNfaEdge(TList_Get(mState.Edges, J));
          If (mEdge.ToState = Self.StartState) And (mEdge.Value = '') Then
          Begin
            mFlag := True;
            Break;
          End;
        End;
        If mFlag Then
        Begin
          Continue;
        End;
      End;

      mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
      mEdge.Value := strnew('');
      mEdge.Others := False;
      mEdge.ToState := Self.StartState;
    End;
  End;
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
  FreeStr(Self.Keyword);
  Self.Keyword := strnew('');

  mState := PNfaState(TList_EmplaceBack(Self.States));
  mState.Acceptable := False;
  mState.Edges := TList_Create(SizeOf(TNfaEdge), 2);
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := strnew('');
  mEdge.Others := False;
  mEdge.ToState := Self.StartState;
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := strnew('');
  mEdge.Others := False;
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
      mEdge.Value := strnew('');
      mEdge.Others := False;
      mEdge.ToState := Self.StartState;
      mState.Acceptable := False;
      mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
      mEdge.Value := strnew('');
      mEdge.Others := False;
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
  FreeStr(Self.Keyword);
  Self.Keyword := strnew('');

  mState := PNfaState(TList_EmplaceBack(Self.States));
  mState.Acceptable := False;
  mState.Edges := TList_Create(SizeOf(TNfaEdge), 2);
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := strnew('');
  mEdge.Others := False;
  mEdge.ToState := Self.StartState;
  mEdge := PNfaEdge(TList_EmplaceBack(mState.Edges));
  mEdge.Value := strnew('');
  mEdge.Others := False;
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
      mEdge.Value := strnew('');
      mEdge.Others := False;
      mEdge.ToState := Self.States.Size - 1;
    End;
  End;

  Self.StartState := Self.States.Size - 2;
End;

Procedure TNfa_Reset(Var Self: PNfa);
Var
  mFalse: Boolean;
  I: TSize;
Begin
  If Self.FAlreadyOn <> nil Then
  Begin
    Dispose(Self.FAlreadyOn);
    Dispose(Self.FOldStates);
    Dispose(Self.FNewStates);
  End;
  Self.FOldStates := TList_Create(SizeOf(TSize), Self.States.Size);
  Self.FNewStates := TList_Create(SizeOf(TSize), Self.States.Size);
  Self.FAlreadyOn := TList_Create(SizeOf(Boolean), Self.States.Size);
  mFalse := False;
  For I := 0 To Self.States.Size - 1 Do
  Begin
    TList_PushBack(Self.FAlreadyOn, @mFalse);
  End;

  TNfa_AddState(Self, Self.StartState);
  TNfa_ExchangeStates(Self);
End;

Function TNfa_Move(Var Self: PNfa; Const Ch: Char): Boolean;
Var
  I: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
  mNot: Boolean;
Begin
  Result := False;
  { TODO: Extract to a procedure called TNfa_MoveByChar? }
  { TODO: BEGIN: }
  While Not TList_IsEmpty(Self.FOldStates) Do
  Begin
    mState := TNfa_GetState(Self, PSize(TList_Back(Self.FOldStates))^);
    If mState.Edges.Size > 0 Then
    Begin
      mEdge := PNfaEdge(TList_Get(mState.Edges, mState.Edges.Size - 1));
      mNot := mEdge.Others;
      If mState.Edges.Size > 1 Then
      Begin
        For I := 0 To mState.Edges.Size - 2 Do
        Begin
          mEdge := PNfaEdge(TList_Get(mState.Edges, I));
          If (strcomp(mEdge.Value, '') <> 0) And (mEdge.Value[0] = Ch) Then
          Begin
            Result := True;
            mNot := False;
            If (Not PBoolean(TList_Get(Self.FAlreadyOn, mEdge.ToState))^) Then
            Begin
              TNfa_AddState(Self, mEdge.ToState);
            End;
          End;
        End;
      End;
      mEdge := PNfaEdge(TList_Get(mState.Edges, mState.Edges.Size - 1));
      If (strcomp(mEdge.Value, '') <> 0) And (mEdge.Others And mNot) Or
        ((Not mEdge.Others) And (mEdge.Value[0] = Ch)) Then
      Begin
        Result := True;
        If (Not PBoolean(TList_Get(Self.FAlreadyOn, mEdge.ToState))^) Then
        Begin
          TNfa_AddState(Self, mEdge.ToState);
        End;
      End;
    End;
    TList_PopBack(Self.FOldStates);
  End;
  { TODO: ^ END. }

  TNfa_ExchangeStates(Self);
End;

Function TNfa_Accepted(Var Self: PNfa): Boolean;
Var
  I: TSize;
  mState: PNfaState;
Begin
  Result := False;
  If Self.FOldStates.Size > 0 Then
  Begin
    For I := 0 To Self.FOldStates.Size - 1 Do
    Begin
      mState := TNfa_GetState(Self, PSize(TList_Get(Self.FOldStates, I))^);
      If mState.Acceptable Then
      Begin
        Result := True;
        Exit;
      End;
    End;
  End;

End;

Function TNfa_Validate(Var Self: PNfa; Input: PChar): Boolean;
Var
  I: TSize;
Begin
  If strcomp(Self.Keyword, '') <> 0 Then
    { TODO And what about if the last state is acceptable? }
  Begin
    Result := (strcomp(Self.Keyword, Input) = 0);
    Exit;
  End;

  TNfa_Reset(Self);
  I := 0;

  While TNfa_Move(Self, Input[I]) Do
  Begin
    Inc(I);
  End;

  Result := TNfa_Accepted(Self);
End;

Procedure TNfa_AddState(Var Self: PNfa; S: TSize);
Var
  mTrue: Boolean;
  mState: PNfaState;
  mEdge: PNfaEdge;
  I: TSize;
Begin
  TList_PushBack(Self.FNewStates, @S);
  mTrue := True;
  TList_Set(Self.FAlreadyOn, S, @mTrue);
  mState := TNfa_GetState(Self, S);
  If mState.Edges.Size > 0 Then
  Begin
    For I := 0 To mState.Edges.Size - 1 Do
    Begin
      mEdge := PNfaEdge(TList_Get(mState.Edges, I));
      If (strcomp(mEdge.Value, '') = 0) And
        (Not PBoolean(TList_Get(Self.FAlreadyOn, mEdge.ToState))^) Then
      Begin
        TNfa_AddState(Self, mEdge.ToState);
      End;
    End;
  End;
End;

Procedure TNfa_ExchangeStates(Var Self: PNfa);
Var
  I: TSize;
  mFalse: Boolean;
Begin
  mFalse := False;
  While Not TList_IsEmpty(Self.FNewStates) Do
  Begin
    I := PSize(TList_Back(Self.FNewStates))^;
    TList_PopBack(Self.FNewStates);
    TList_PushBack(Self.FOldStates, @I);
    TList_Set(Self.FAlreadyOn, I, @mFalse);
  End;
End;

End.
