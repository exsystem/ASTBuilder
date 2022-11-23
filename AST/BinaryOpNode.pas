Unit BinaryOpNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  TOpType = (eMultiply, eRealDivide, eIntDivide, eModulo, eAnd, eShiftLeft,
    eShiftRight, eAs, eAdd, eSubtract, eOr, eXor, eEqual, eNotEqual, eLT,
    eGT, eLE, eGE, eIn, eIs);

  PBinaryOpNode = ^TBinaryOpNode;

  TBinaryOpNode = Record
    Parent: TAstNode;
    OpType: TOpType;
    LeftNode: PASTNode;
    RightNode: PASTNode;
  End;

Procedure TBinaryOpNode_Create(Self: PBinaryOpNode);
Procedure TBinaryOpNode_Destroy(Self: PAstNode);
Procedure TBinaryOpNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Implementation

Procedure TBinaryOpNode_Create(Self: PBinaryOpNode);
Begin
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT.Destory := TBinaryOpNode_Destroy;
  Self.Parent.VMT.Accept := TBinaryOpNode_Accept;
  Self.LeftNode := nil;
  Self.RightNode := nil;
End;

Procedure TBinaryOpNode_Destroy(Self: PAstNode);
Begin
  If PBinaryOpNode(Self).LeftNode <> nil Then
  Begin
    PBinaryOpNode(Self).LeftNode.VMT.Destory(PBinaryOpNode(Self).LeftNode);
    Dispose(PBinaryOpNode(Self).LeftNode);
  End;
  If PBinaryOpNode(Self).RightNode <> nil Then
  Begin
    PBinaryOpNode(Self).RightNode.VMT.Destory(PBinaryOpNode(Self).RightNode);
    Dispose(PBinaryOpNode(Self).RightNode);
  End;
  TAstNode_Destroy(Self);
End;

Procedure TBinaryOpNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitBinaryOp(Visitor, Self);
End;
End.
