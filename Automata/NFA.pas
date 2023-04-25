Unit NFA;

{$I define.inc}
Interface

Uses
  List, TypeDef;

Type
  TNfaEdgeType = (TNfaEdgeType_Char, TNfaEdgeType_Others, TNfaEdgeType_Any);

  PNfaState = ^TNfaState;

  TNfaState = Record
    Acceptable: Boolean;
    Greedy: Boolean;
    Edges: PList; { of TEdge }
  End;

  PNfaEdge = ^TNfaEdge;

  TNfaEdge = Record
    Value: PChar;
    EdgeType: TNfaEdgeType;
    ToState: TSize;
  End;

  TStateOp = (TStateOp_Root, TStateOp_Left, TStateOp_Right, TStateOp_End,
    TStateOp_State);

  PNfaStateInstruction = ^TNfaStateInstruction;

  TNfaStateInstruction = Record
    Op: TStateOp;
    Arg: TSize;
  End;

  TNfaPartition = (TNfaPartition_Left, TNfaPartition_Right);

  PNfaStateStatus = ^TNfaStateStatus;

  TNfaStateStatus = Record
    State: TSize;
    SameRootState: Boolean;
    Partition: TNfaPartition;
    LeftMatched: Boolean;
  End;

  PNfa = ^TNfa;

  TNfa = Record
    StartState: TSize;
    States: PList; { of TNfaState }
    FNewStates: PList; { of TNfaStateInstruction }
    FOldStates: PList; { of TNfaStateInstruction }
    FAlreadyOn: PList; { of Boolean }
    Keyword: PChar;
  End;

Procedure TNfa_Create(Var Self: PNfa);
Procedure TNfa_Destroy(Self: PNfa);
Function TNfa_GetState(Self: PNfa; StateIndex: TSize): PNfaState;
Procedure TNfa_AddEdge(Self: PNfa; Value: PChar; Source: TSize; Destination: TSize);
Procedure TNfa_AnyChar(Self: PNfa; Source: TSize; Destination: TSize);
Procedure TNfa_MergeChars(Self: PNfa; Nfa: PNfa);
{
  TODO: extend the procedure below to accept mutiple NFAs into one NFA, not only two.
}
Procedure TNfa_Concat(Var Self: PNfa; Nfa: PNfa);
{
  TODO: extend the procedure below to accept mutiple NFAs into one NFA, not only two.
}
Procedure TNfa_Alternative(Var Self: PNfa; Nfa: PNfa);
Procedure TNfa_Multiple(Var Self: PNfa; Greedy: Boolean);
Procedure TNfa_Optional(Var Self: PNfa; Greedy: Boolean);
Procedure TNfa_OneOrMore(Var Self: PNfa; Greedy: Boolean);
Procedure TNfa_Not(Var Self: PNfa);
Procedure TNfa_Reset(Var Self: PNfa);
Function TNfa_Match(Var Self: PNfa; Const Ch: Char; Const State: TSize): Boolean;
Function TNfa_Move(Var Self: PNfa; Const Ch: Char): Boolean;
Function TNfa_Accepted(Var Self: PNfa): Boolean;
{
  SEE: <<Compilers: Principles, Techniques, and Tools (2nd Edition)>>: Chapter.3.7.2 / Page.156~158
}
Function TNfa_Validate(Var Self: PNfa; Input: PChar): Boolean;
{
  TODO: rename to TNfa_AddEpsilonClosureStates?
}
Procedure TNfa_AddState(Var Self: PNfa; Op: TStateOp; Arg: TSize);
{
  TODO: rename to TNfa_PrepareOldStatesForNextTurn?
}
Procedure TNfa_ExchangeStates(Var Self: PNfa);

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil, Utility;

Procedure TNfa_Create(Var Self: PNfa);
Var
  mState: PNfaState;
Begin
  New(Self);
  Self^.States := TList_Create(SizeOf(TNfaState), 5);
  Self^.StartState := 0;
  mState := TList_EmplaceBack(Self^.States);
  mState^.Acceptable := False;
  mState^.Greedy := True;
  mState^.Edges := TList_Create(SizeOf(TNfaEdge), 1);
  Self^.Keyword := strnew('');
  Self^.FAlreadyOn := nil;
  Self^.FOldStates := nil;
  Self^.FNewStates := nil;
End;

Procedure TNfa_Destroy(Self: PNfa);
Var
  I, J: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  If Self^.FAlreadyOn <> nil Then
  Begin
    Dispose(Self^.FAlreadyOn);
    Dispose(Self^.FOldStates);
    Dispose(Self^.FNewStates);
  End;
  FreeStr(Self^.Keyword);
  For I := 0 To Self^.States^.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Self^.States, I));
    If mState^.Edges^.Size > 0 Then
    Begin
      For J := 0 To mState^.Edges^.Size - 1 Do
      Begin
        mEdge := PNfaEdge(TList_Get(mState^.Edges, J));
        FreeStr(mEdge^.Value);
      End;
    End;
    TList_Destroy(mState^.Edges);
  End;
  TList_Destroy(Self^.States);
  Dispose(Self);
End;

Function TNfa_GetState(Self: PNfa; StateIndex: TSize): PNfaState;
Begin
  Result := PNfaState(TList_Get(Self^.States, StateIndex));
End;

Procedure TNfa_AddEdge(Self: PNfa; Value: PChar; Source: TSize; Destination: TSize);
Var
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  mState := PNfaState(TList_Get(Self^.States, Source));
  If (Source = Self^.States^.Size - 1) And (Destination = Self^.States^.Size) And
    (mState^.Edges^.Size = 0) Then
  Begin
    Self^.Keyword := ReallocStr(Self^.Keyword, strlen(Self^.Keyword) + strlen(Value));
    strcat(Self^.Keyword, Value);
  End
  Else
  Begin
    FreeStr(Self^.Keyword);
    Self^.Keyword := strnew('');
  End;
  mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
  mEdge^.Value := strnew(Value);
  mEdge^.EdgeType := TNfaEdgeType_Char;
  mEdge^.ToState := Destination;
  If Destination = Self^.States^.Size Then
  Begin
    mState := PNfaState(TList_EmplaceBack(Self^.States));
    mState^.Edges := TList_Create(SizeOf(TNfaEdge), 1);
    mState^.Greedy := True;
  End;
End;

Procedure TNfa_AnyChar(Self: PNfa; Source: TSize; Destination: TSize);
Var
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  FreeStr(Self^.Keyword);
  Self^.Keyword := strnew('');

  mState := PNfaState(TList_Get(Self^.States, Source));
  mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
  mEdge^.Value := strnew('');
  mEdge^.EdgeType := TNfaEdgeType_Any;
  mEdge^.ToState := Destination;
  If Destination = Self^.States^.Size Then
  Begin
    mState := PNfaState(TList_EmplaceBack(Self^.States));
    mState^.Edges := TList_Create(SizeOf(TNfaEdge), 1);
    mState^.Greedy := True;
  End;
End;

Procedure TNfa_MergeChars(Self: PNfa; Nfa: PNfa);
Var
  mState, mNfaState: PNfaState;
  mEdge, mNfaEdge: PNfaEdge;
  I, J: TSize;
Begin
  { TODO check if this operation is allowed by Self and Nfa }
  mState := PNfaState(TList_Get(Self^.States, 0));
  mNfaState := PNfaState(TList_Get(Nfa^.States, 0));
  For I := 0 To mNfaState^.Edges^.Size - 1 Do
  Begin
    mNfaEdge := PNfaEdge(TList_Get(mNfaState^.Edges, I));
    For J := 0 To mState^.Edges^.Size - 1 Do
    Begin
      mEdge := PNfaEdge(TList_Get(mState^.Edges, J));
      If strcomp(mEdge^.Value, mNfaEdge^.Value) = 0 Then
      Begin
        TNfa_Destroy(Nfa);
        Exit;
      End;
    End;
  End;
  For I := 0 To mNfaState^.Edges^.Size - 1 Do
  Begin
    mNfaEdge := PNfaEdge(TList_Get(mNfaState^.Edges, I));
    mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
    mEdge^.Value := strnew(mNfaEdge^.Value);
    mEdge^.EdgeType := TNfaEdgeType_Char;
    mEdge^.ToState := 1;
  End;
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
  If (strcomp(Self^.Keyword, '') = 0) Or (strcomp(Nfa^.Keyword, '') = 0) Then
  Begin
    FreeStr(Self^.Keyword);
    Self^.Keyword := strnew('');
  End
  Else
  Begin
    Self^.Keyword := ReallocStr(Self^.Keyword, strlen(Self^.Keyword) +
      strlen(Nfa^.Keyword));
    strcopy(Self^.Keyword, Nfa^.Keyword);
  End;
  FreeStr(Nfa^.Keyword);
  For I := 0 To Self^.States^.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Self^.States, I));
    If mState^.Acceptable Then
    Begin
      mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
      mEdge^.Value := strnew('');
      mEdge^.EdgeType := TNfaEdgeType_Char;
      mEdge^.ToState := Nfa^.StartState + Self^.States^.Size;
      mState^.Acceptable := False;
    End;
  End;
  For I := 0 To Nfa^.States^.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Nfa^.States, I));
    If mState^.Edges^.Size > 0 Then
    Begin
      For J := 0 To mState^.Edges^.Size - 1 Do
      Begin
        mEdge := PNfaEdge(TList_Get(mState^.Edges, J));
        Inc(mEdge^.ToState, Self^.States^.Size);
      End;
    End;
  End;
  For I := 0 To Nfa^.States^.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Nfa^.States, I));
    Move(mState^, PNfaState(TList_EmplaceBack(Self^.States))^, SizeOf(TNfaState));
  End;
  TList_Destroy(Nfa^.States);
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
  If (strcomp(Self^.Keyword, '') = 0) Xor (strcomp(Nfa^.Keyword, '') = 0) Then
  Begin
    Self^.Keyword := ReallocStr(Self^.Keyword, strlen(Self^.Keyword) +
      strlen(Nfa^.Keyword));
    strcat(Self^.Keyword, Nfa^.Keyword);
  End
  Else
  Begin
    FreeStr(Self^.Keyword);
    Self^.Keyword := strnew('');
  End;
  FreeStr(Nfa^.Keyword);
  For I := 0 To Nfa^.States^.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Nfa^.States, I));
    If mState^.Edges^.Size > 0 Then
    Begin
      For J := 0 To mState^.Edges^.Size - 1 Do
      Begin
        mEdge := PNfaEdge(TList_Get(mState^.Edges, J));
        Inc(mEdge^.ToState, Self^.States^.Size);
      End;
    End;
    Move(mState^, PNfaState(TList_EmplaceBack(Self^.States))^, SizeOf(TNfaState));
  End;
  mState := PNfaState(TList_EmplaceBack(Self^.States));
  mState^.Acceptable := False;
  mState^.Greedy := True;
  mState^.Edges := TList_Create(SizeOf(TNfaEdge), 2);
  mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
  mEdge^.Value := strnew('');
  mEdge^.EdgeType := TNfaEdgeType_Char;
  mEdge^.ToState := Self^.StartState;
  mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
  mEdge^.Value := strnew('');
  mEdge^.EdgeType := TNfaEdgeType_Char;
  mEdge^.ToState := Nfa^.StartState + (Self^.States^.Size - 1) - Nfa^.States^.Size;
  Self^.StartState := Self^.States^.Size - 1;
  mState := PNfaState(TList_EmplaceBack(Self^.States));
  mState^.Acceptable := True;
  mState^.Greedy := True;
  mState^.Edges := TList_Create(SizeOf(TNfaEdge), 1);
  For I := 0 To Self^.States^.Size - 3 Do
  Begin
    mState := PNfaState(TList_Get(Self^.States, I));
    If mState^.Acceptable Then
    Begin
      mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
      mEdge^.Value := strnew('');
      mEdge^.EdgeType := TNfaEdgeType_Char;
      mEdge^.ToState := Self^.States^.Size - 1;
      mState^.Acceptable := False;
    End;
  End;
  TList_Destroy(Nfa^.States);
  Dispose(Nfa);
End;

{
  A := ~A ; // A only contains one char.
}
Procedure TNfa_Not(Var Self: PNfa);
Var
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  FreeStr(Self^.Keyword);
  Self^.Keyword := strnew('');
  mState := PNfaState(TList_Get(Self^.States, 0));
  mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
  mEdge^.Value := strnew('~');
  mEdge^.EdgeType := TNfaEdgeType_Others;
  mEdge^.ToState := 2;
  mState := PNfaState(TList_Get(Self^.States, 1));
  mState^.Acceptable := False;
  mState := PNfaState(TList_EmplaceBack(Self^.States));
  mState^.Acceptable := True;
  mState^.Greedy := True;
  mState^.Edges := TList_Create(SizeOf(TNfaEdge), 1);
End;

{
  A := A + ;
}
Procedure TNfa_OneOrMore(Var Self: PNfa; Greedy: Boolean);
Var
  I, J: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
  mFlag: TSize;
Begin
  FreeStr(Self^.Keyword);
  Self^.Keyword := strnew('');
  For I := 0 To Self^.States^.Size - 1 Do
  Begin
    mState := PNfaState(TList_Get(Self^.States, I));
    If mState^.Acceptable Then
    Begin
      mState^.Greedy := Greedy;
      mFlag := mState^.Edges^.Size;
      If mState^.Edges^.Size > 0 Then
      Begin
        For J := 0 To mState^.Edges^.Size - 1 Do
        Begin
          mEdge := PNfaEdge(TList_Get(mState^.Edges, J));
          If (mEdge^.ToState = Self^.StartState) And (strcomp(mEdge^.Value, '') = 0) Then
          Begin
            mFlag := J;
            Break;
          End;
        End;
      End;
      If mFlag = mState^.Edges^.Size Then
      Begin
        mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
        mEdge^.Value := strnew('');
        mEdge^.EdgeType := TNfaEdgeType_Char;
        mEdge^.ToState := Self^.StartState;
      End;
      If mState^.Edges^.Size > 1 Then
      Begin
        Swap(SizeOf(TNfaEdge), TList_Get(mState^.Edges, 0),
          TList_Get(mState^.Edges, mFlag));
      End;
    End;
  End;
End;

{
  A := A * ;
}
Procedure TNfa_Multiple(Var Self: PNfa; Greedy: Boolean);
Var
  I: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  FreeStr(Self^.Keyword);
  Self^.Keyword := strnew('');
  mState := PNfaState(TList_EmplaceBack(Self^.States));
  mState^.Acceptable := False;
  mState^.Greedy := Greedy;
  mState^.Edges := TList_Create(SizeOf(TNfaEdge), 2);
  mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
  mEdge^.Value := strnew('');
  mEdge^.EdgeType := TNfaEdgeType_Char;
  mEdge^.ToState := Self^.States^.Size;
  mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
  mEdge^.Value := strnew('');
  mEdge^.EdgeType := TNfaEdgeType_Char;
  mEdge^.ToState := Self^.StartState;
  mState := PNfaState(TList_EmplaceBack(Self^.States));
  mState^.Acceptable := True;
  mState^.Greedy := True;
  mState^.Edges := TList_Create(SizeOf(TNfaEdge), 1);
  For I := 0 To Self^.States^.Size - 3 Do
  Begin
    mState := PNfaState(TList_Get(Self^.States, I));
    If mState^.Acceptable Then
    Begin
      mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
      mEdge^.Value := strnew('');
      mEdge^.EdgeType := TNfaEdgeType_Char;
      mEdge^.ToState := Self^.States^.Size - 1;

      mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
      mEdge^.Value := strnew('');
      mEdge^.EdgeType := TNfaEdgeType_Char;
      mEdge^.ToState := Self^.StartState;

      mState^.Greedy := Greedy;
      mState^.Acceptable := False;
    End;
  End;
  Self^.StartState := Self^.States^.Size - 2;
End;

{
  A' := A ? ;
}
Procedure TNfa_Optional(Var Self: PNfa; Greedy: Boolean);
Var
  I: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
Begin
  FreeStr(Self^.Keyword);
  Self^.Keyword := strnew('');

  mState := PNfaState(TList_EmplaceBack(Self^.States));
  mState^.Acceptable := False;
  mState^.Greedy := Greedy;
  mState^.Edges := TList_Create(SizeOf(TNfaEdge), 2);

  mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
  mEdge^.Value := strnew('');
  mEdge^.EdgeType := TNfaEdgeType_Char;
  mEdge^.ToState := Self^.States^.Size;

  mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
  mEdge^.Value := strnew('');
  mEdge^.EdgeType := TNfaEdgeType_Char;
  mEdge^.ToState := Self^.StartState;

  mState := PNfaState(TList_EmplaceBack(Self^.States));
  mState^.Acceptable := True;
  mState^.Greedy := True;
  mState^.Edges := TList_Create(SizeOf(TNfaEdge), 1);
  For I := 0 To Self^.States^.Size - 3 Do
  Begin
    mState := PNfaState(TList_Get(Self^.States, I));
    If mState^.Acceptable Then
    Begin
      mState^.Acceptable := False;
      mEdge := PNfaEdge(TList_EmplaceBack(mState^.Edges));
      mEdge^.Value := strnew('');
      mEdge^.EdgeType := TNfaEdgeType_Char;
      mEdge^.ToState := Self^.States^.Size - 1;
    End;
  End;
  Self^.StartState := Self^.States^.Size - 2;
End;

Procedure TNfa_Reset(Var Self: PNfa);
Var
  mFalse: Boolean;
  I: TSize;
Begin
  If Self^.FAlreadyOn <> nil Then
  Begin
    Dispose(Self^.FAlreadyOn);
    Dispose(Self^.FOldStates);
    Dispose(Self^.FNewStates);
  End;
  Self^.FOldStates := TList_Create(SizeOf(TNfaStateInstruction), Self^.States^.Size);
  Self^.FNewStates := TList_Create(SizeOf(TNfaStateInstruction), Self^.States^.Size);
  Self^.FAlreadyOn := TList_Create(SizeOf(Boolean), Self^.States^.Size);
  mFalse := False;
  For I := 0 To Self^.States^.Size - 1 Do
  Begin
    TList_PushBack(Self^.FAlreadyOn, @mFalse);
  End;
  TNfa_AddState(Self, TStateOp_Root, Self^.StartState);
  TNfa_ExchangeStates(Self);
End;

Function TNfa_Match(Var Self: PNfa; Const Ch: Char; Const State: TSize): Boolean;
Var
  I: TSize;
  mState: PNfaState;
  mEdge: PNfaEdge;
  mRealOthers: Boolean;
Begin
  Result := False;
  mState := TNfa_GetState(Self, State);
  If mState^.Edges^.Size > 0 Then
  Begin
    mEdge := PNfaEdge(TList_Get(mState^.Edges, mState^.Edges^.Size - 1));
    If ((mEdge^.EdgeType = TNfaEdgeType_Others) And
      (StrComp(mEdge^.Value, '') <> 0)) Then
    Begin
      mRealOthers := True;
      For I := 0 To mState^.Edges^.Size - 2 Do
      Begin
        mEdge := PNfaEdge(TList_Get(mState^.Edges, I));
        If ((strcomp(mEdge^.Value, '') <> 0) And (mEdge^.Value[0] = Ch)) Or
          (mEdge^.EdgeType = TNfaEdgeType_Any) Then
        Begin
          mRealOthers := False;
          Break;
        End;
      End;
      If mRealOthers Then
      Begin
        mEdge := PNfaEdge(TList_Get(mState^.Edges, mState^.Edges^.Size - 1));
        If Not PBoolean(TList_Get(Self^.FAlreadyOn, mEdge^.ToState))^ Then
        Begin
          TNfa_AddState(Self, TStateOp_Root, mEdge^.ToState);
        End;
        Result := True;
      End;
    End
    Else
    Begin
      For I := 0 To mState^.Edges^.Size - 1 Do
      Begin
        mEdge := PNfaEdge(TList_Get(mState^.Edges, I));
        If (strcomp(mEdge^.Value, '') <> 0) And (mEdge^.Value[0] = Ch) Or
          (mEdge^.EdgeType = TNfaEdgeType_Any) Then
        Begin
          If Not PBoolean(TList_Get(Self^.FAlreadyOn, mEdge^.ToState))^ Then
          Begin
            TNfa_AddState(Self, TStateOp_Root, mEdge^.ToState);
          End;
          Result := True;
        End;
      End;
    End;
  End;
End;


Function TNfa_Move(Var Self: PNfa; Const Ch: Char): Boolean;
Var
  mCurrInst: TNfaStateInstruction;
  mOpStatus: PList;
  mStatus: TNfaStateStatus;
Begin
  Result := False;
  mOpStatus := TList_Create(SizeOf(TNfaStateStatus), 1);

  While Not TList_IsEmpty(Self^.FOldStates) Do
  Begin
    mCurrInst := PNfaStateInstruction(TList_Back(Self^.FOldStates))^;
    Case mCurrInst.Op Of
      TStateOp_Root:
      Begin
        If TNfa_Match(Self, Ch, mCurrInst.Arg) Then
        Begin
          Result := True;
        End;
      End;
      TStateOp_State:
      Begin
        If mOpStatus^.Size = 0 Then
        Begin
          If TNfa_Match(Self, Ch, mCurrInst.Arg) Then
          Begin
            Result := True;
          End;
        End
        Else
        Begin
          mStatus := PNfaStateStatus(TList_Back(mOpStatus))^;
          If (Not mStatus.SameRootState) Or (mStatus.Partition = TNfaPartition_Left) Or
            (Not mStatus.LeftMatched) Then
          Begin
            If TNfa_Match(Self, Ch, mCurrInst.Arg) Then
            Begin
              Result := True;
              mStatus.LeftMatched := True;
              TList_PopBack(mOpStatus);
              TList_PushBack(mOpStatus, @mStatus);
            End;
          End;
        End;
      End;
      TStateOp_Left:
      Begin
        mStatus.State := mCurrInst.Arg;
        mStatus.SameRootState := True;
        mStatus.Partition := TNfaPartition_Left;
        mStatus.LeftMatched := False;
        TList_PushBack(mOpStatus, @mStatus);
      End;
      TStateOp_Right:
      Begin
        If mOpStatus^.Size > 0 Then
        Begin
          mStatus := PNfaStateStatus(TList_Back(mOpStatus))^;
          If mStatus.State = mCurrInst.Arg Then
          Begin
            mStatus.Partition := TNfaPartition_Right;
            mStatus.SameRootState := (mCurrInst.Arg = mStatus.State);
            TList_PopBack(mOpStatus);
            TList_PushBack(mOpStatus, @mStatus);
          End;
        End;
      End;
      TStateOp_End:
      Begin
        If mOpStatus^.Size > 0 Then
        Begin
          mStatus := PNfaStateStatus(TList_Back(mOpStatus))^;
          If mStatus.State = mCurrInst.Arg Then
          Begin
            TList_PopBack(mOpStatus);
          End;
        End;
      End;
    End;

    TList_PopBack(Self^.FOldStates);
  End;

  TList_Destroy(mOpStatus);
  TNfa_ExchangeStates(Self);
End;

Function TNfa_Accepted(Var Self: PNfa): Boolean;
Var
  I: TSize;
  mState: PNfaState;
  mInst: TNfaStateInstruction;
Begin
  Result := False;
  If Self^.FOldStates^.Size > 0 Then
  Begin
    For I := 0 To Self^.FOldStates^.Size - 1 Do
    Begin
      mInst := PNfaStateInstruction(TList_Get(Self^.FOldStates, I))^;
      If Not (mInst.Op In [TStateOp_Root, TStateOp_State]) Then
      Begin
        Continue;
      End;
      mState := TNfa_GetState(Self, mInst.Arg);
      If mState^.Acceptable Then
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
  If strcomp(Self^.Keyword, '') <> 0 Then
    { TODO And what about if the last state is acceptable? }
  Begin
    Result := (strcomp(Self^.Keyword, Input) = 0);
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

Procedure TNfa_AddState(Var Self: PNfa; Op: TStateOp; Arg: TSize);
Var
  mTrue: Boolean;
  mState: PNfaState;
  mEdge: PNfaEdge;
  I: TSize;
  mStateInst: TNfaStateInstruction;
Begin
  mStateInst.Op := Op;
  mStateInst.Arg := Arg;
  TList_PushBack(Self^.FNewStates, @mStateInst);
  If Op In [TStateOp_Left, TStateOp_Right, TStateOp_End] Then
  Begin
    Exit;
  End;
  mTrue := True;
  TList_Set(Self^.FAlreadyOn, Arg, @mTrue);
  mState := TNfa_GetState(Self, Arg);
  If mState^.Edges^.Size > 0 Then
  Begin
    For I := 0 To mState^.Edges^.Size - 1 Do
    Begin
      If I = 0 Then
      Begin
        If mState^.Greedy Then
        Begin
          TNfa_AddState(Self, TStateOp_Right, Arg);
        End
        Else
        Begin
          TNfa_AddState(Self, TStateOp_Left, Arg);
        End;
      End;

      If (Not mState^.Greedy) And (I = 1) Then
      Begin
        TNfa_AddState(Self, TStateOp_Right, Arg);
      End;

      mEdge := PNfaEdge(TList_Get(mState^.Edges, I));
      If (strcomp(mEdge^.Value, '') = 0) And (mEdge^.EdgeType = TNfaEdgeType_Char) And
        (Not PBoolean(TList_Get(Self^.FAlreadyOn, mEdge^.ToState))^) Then
      Begin
        TNfa_AddState(Self, TStateOp_State, mEdge^.ToState);
      End;
    End;
    TNfa_AddState(Self, TStateOp_End, Arg);
  End;
End;

Procedure TNfa_ExchangeStates(Var Self: PNfa);
Var
  I: TNfaStateInstruction;
  mFalse: Boolean;
Begin
  mFalse := False;
  While Not TList_IsEmpty(Self^.FNewStates) Do
  Begin
    I := PNfaStateInstruction(TList_Back(Self^.FNewStates))^;
    TList_PopBack(Self^.FNewStates);
    TList_PushBack(Self^.FOldStates, @I);
    If I.Op In [TStateOp_Root, TStateOp_State] Then
    Begin
      TList_Set(Self^.FAlreadyOn, I.Arg, @mFalse);
    End;
  End;
End;

End.
