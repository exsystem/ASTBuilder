Unit LiteralNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  TLiteralType = (eNumber);

  PLiteralNode = ^TLiteralNode;

  TLiteralNode = Record
    Parent: TAstNode;
    NodeType: TLiteralType;
    Value: String;
  End;

Procedure TLiteralNode_Create(Self: PLiteralNode; NodeType: TLiteralType;
  Value: String);
Procedure TLiteralNode_Destroy(Self: PAstNode);
Procedure TLiteralNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Implementation

Procedure TLiteralNode_Create(Self: PLiteralNode; NodeType: TLiteralType;
  Value: String);
Begin
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT.Destory := TLiteralNode_Destroy;
  Self.Parent.VMT.Accept := TLiteralNode_Accept;

  Self.NodeType := NodeType;
  Self.Value := Value;
End;

Procedure TLiteralNode_Destroy(Self: PAstNode);
Begin
  TAstNode_Destroy(Self);
End;

Procedure TLiteralNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitLiteral(Visitor, Self);
End;

End.
