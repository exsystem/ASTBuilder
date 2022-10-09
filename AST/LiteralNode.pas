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
    Parent: TAstNode;
    NodeType: TLiteralType;
    Value: String;
  End;

Procedure TLiteralNode_Create(Self: PLiteralNode; NodeType: TLiteralType;
  Value: String);
Procedure TLiteralNode_Destroy(Self: PAstNode);

Implementation

Procedure TLiteralNode_Create(Self: PLiteralNode; NodeType: TLiteralType;
  Value: String);
Begin
  TAstNode_Create(PAstNode(Self), $2);
  Self.Parent.VMT.Destory := TLiteralNode_Destroy;

  Self.NodeType := NodeType;
  Self.Value := Value;
End;

Procedure TLiteralNode_Destroy(Self: PAstNode);
Begin
  TAstNode_Destroy(Self);
End;


End.
