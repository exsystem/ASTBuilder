Unit BinaryOpNode;

Interface

Uses
  ASTNode;

Type
  TOpType = (ePlus, eMinus, eMultiply, eDivide);

  PBinaryOpNode = ^TBinaryOpNode;

  TBinaryOpNode = Record
    OpType: TOpType;
    LeftNode: PASTNode;
    RightNode: PASTNode;
  End;

Function TBinaryOpNode_Create(): PAstNode;
Procedure TBinaryOpNode_Destroy(Self: PAstNode);

Implementation

Function TBinaryOpNode_Create(): PAstNode;
Var
  mData: PBinaryOpNode;
Begin
  Result := TAstNode_Create($1);
  New(mData);
  mData.LeftNode := nil;
  mData.RightNode := nil;
  Result.Data := mData;
End;

Procedure TBinaryOpNode_Destroy(Self: PAstNode);
Var
  mData: PBinaryOpNode;
Begin
  mData := PBinaryOpNode(Self.Data);
  If mData.LeftNode <> nil Then
    TAstNode_Destroy(mData.LeftNode);
  If mData.RightNode <> nil Then
    TAstNode_Destroy(mData.RightNode);
  Dispose(mData);
End;

End.
