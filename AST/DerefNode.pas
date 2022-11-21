Unit DerefNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Const
  CNodeType = Byte($04);

Type
  PDerefNode = ^TDerefNode;

  TDerefNode = Record
    Parent: TAstNode;
    Expression: PAstNode;
  End;

Procedure TDerefNode_Create(Self: PDerefNode; Expression: PAstNode);
Procedure TDerefNode_Destroy(Self: PAstNode);

Implementation

Procedure TDerefNode_Create(Self: PDerefNode; Expression: PAstNode);
Begin
  TAstNode_Create(PAstNode(Self), CNodeType);
  Self.Parent.VMT.Destory := TDerefNode_Destroy;

  Self.Expression := Expression;
End;

Procedure TDerefNode_Destroy(Self: PAstNode);
Begin
  If PDerefNode(Self).Expression <> nil Then
  Begin
    PDerefNode(Self).Expression.VMT.Destory(PDerefNode(Self).Expression);
    Dispose(PDerefNode(Self).Expression);
  End;
  TAstNode_Destroy(Self);
End;

End.
