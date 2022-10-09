Unit BinaryOpNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  TOpType = (ePlus, eMinus, eMultiply, eDivide);

  PBinaryOpNode = ^TBinaryOpNode;

  TBinaryOpNode = Record
    Parent: TAstNode;
    OpType: TOpType;
    LeftNode: PASTNode;
    RightNode: PASTNode;
  End;

Procedure TBinaryOpNode_Create(Self: PBinaryOpNode);
Procedure TBinaryOpNode_Destroy(Self: PAstNode);

Implementation

Procedure TBinaryOpNode_Create(Self: PBinaryOpNode);
Begin
  TAstNode_Create(PAstNode(Self), $1);
  Self.Parent.VMT.Destory := TBinaryOpNode_Destroy;
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

End.
