Unit ArrayAccessNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode, List;

Type
  PArrayAccessNode = ^TArrayAccessNode;

  TArrayAccessNode = Record
    Parent: TAstNode;
    ArrayExpression: PAstNode;
    Indices: PList; // Of PAstNode
  End;

Procedure TArrayAccessNode_Create(Self: PArrayAccessNode; ArrayExpression: PAstNode);
Procedure TArrayAccessNode_Destroy(Self: PAstNode);
Procedure TArrayAccessNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Implementation

Uses
  TypeDef;

Procedure TArrayAccessNode_Create(Self: PArrayAccessNode; ArrayExpression: PAstNode);
Begin
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT.Destory := TArrayAccessNode_Destroy;
  Self.Parent.VMT.Accept := TArrayAccessNode_Accept;

  Self.ArrayExpression := ArrayExpression;
  Self.Indices := TList_Create(SizeOf(PAstNode), 1);
End;

Procedure TArrayAccessNode_Destroy(Self: PAstNode);
Var
  I: TSize;
  mElem: PAstNode;
Begin
  If PArrayAccessNode(Self).ArrayExpression <> nil Then
  Begin
    PArrayAccessNode(Self).ArrayExpression.VMT.Destory(
      PArrayAccessNode(Self).ArrayExpression);
    Dispose(PArrayAccessNode(Self).ArrayExpression);
  End;
  For I := 0 To PArrayAccessNode(Self).Indices.Size - 1 Do
  Begin
    mElem := PPAstNode(TList_Get(PArrayAccessNode(Self).Indices, I))^;
    mElem.VMT.Destory(mElem);
    Dispose(mElem);
  End;
  TList_Destroy(PArrayAccessNode(Self).Indices);
  TAstNode_Destroy(Self);
End;

Procedure TArrayAccessNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitArrayAccess(Visitor, Self);
End;

End.
