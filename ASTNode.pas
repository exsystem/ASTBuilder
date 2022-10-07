Unit ASTNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Type
  PAstNode = ^TAstNode;

  TAstNode = Record
    NodeType: Byte;
    Data: Pointer;
  End;

Function TAstNode_Create(NodeType: Byte): PAstNode;
Procedure TAstNode_Destroy(Self: PAstNode);

Implementation

Uses
  BinaryOpNode, LiteralNode;

Function TAstNode_Create(NodeType: Byte): PAstNode;
Begin
  New(Result);
  Result.NodeType := NodeType;
End;

Procedure TAstNode_Destroy(Self: PAstNode);
Begin
  Case Self.NodeType Of
    $1:
      TBinaryOpNode_Destroy(Self);
    $2:
      TLiteralNode_Destroy(Self);
  End;
  Dispose(Self);
End;

End.
