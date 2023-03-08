{ Unit GroupNode; }
Unit GrpNode;

{$I define.inc}

Interface

Uses
  ASTNode, List;

Type

  TGroupType = (eGroup, eOptional, eMultiple);

  PGroupNode = ^TGroupNode;

  TGroupNode = Record
    Parent: TAstNode;
    Terms: PList; { Of PAstNode }
    IsAlternational: Boolean;
    GroupType: TGroupType;
  End;

Procedure TGroupNode_Create(Var Self: PGroupNode);

Procedure TGroupNode_Destroy(Self: PAstNode);

Procedure TGroupNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTGroupNode_VMT: TAstNode_VMT;

Implementation

Uses
  TypeDef;

Procedure TGroupNode_Create(Var Self: PGroupNode);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self^.Parent.VMT := @mTGroupNode_VMT;

  Self^.Terms := TList_Create(SizeOf(PAstNode), 1);
End;

Procedure TGroupNode_Destroy(Self: PAstNode);
Var
  I: TSize;
  mElem: PAstNode;
Begin
  For I := 0 To PGroupNode(Self)^.Terms^.Size - 1 Do
  Begin
    mElem := PPAstNode(TList_Get(PGroupNode(Self)^.Terms, I))^;
    If mElem <> nil Then { nil for epsilon term in the alternation group. }
    Begin
      mElem^.VMT^.Destory(mElem);
      Dispose(mElem);
    End;
  End;
  TList_Destroy(PGroupNode(Self)^.Terms);
  TAstNode_Destroy(Self);
End;

Procedure TGroupNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor^.VMT^.VisitGroup(Visitor, Self);
End;

Begin
  mTGroupNode_VMT.Destory := TGroupNode_Destroy;
  mTGroupNode_VMT.Accept := TGroupNode_Accept;

End.
