Unit LiteralNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  TLiteralType = (eInteger);

  PLiteralNode = ^TLiteralNode;

  TLiteralNode = Record
    NodeType: TLiteralType;
    Value: String;
  End;

Function TLiteralNode_Create(NodeType: TLiteralType; Value: String): PAstNode;
Procedure TLiteralNode_Destroy(Self: PAstNode);

Implementation

Function TLiteralNode_Create(NodeType: TLiteralType; Value: String): PAstNode;
Var
  mData: PLiteralNode;
Begin
  Result := TAstNode_Create($2);
  New(mData);
  mData.NodeType := NodeType;
  mData.Value := Value;
  Result.Data := mData;
End;

Procedure TLiteralNode_Destroy(Self: PAstNode);
Var
  mData: PLiteralNode;
Begin
  mData := PLiteralNode(Self.Data);
  Dispose(mData);
End;


End.
