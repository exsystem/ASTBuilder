Unit UnaryOpNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  TOpType = (eAddress, eNot, ePositive, eNegative);

  PUnaryOpNode = ^TUnaryOpNode;

  TUnaryOpNode = Record
    Parent: TAstNode;
    OpType: TOpType;
    Value: PASTNode;
  End;

Procedure TUnaryOpNode_Create(Self: PUnaryOpNode);
Procedure TUnaryOpNode_Destroy(Self: PAstNode);

Implementation

Procedure TUnaryOpNode_Create(Self: PUnaryOpNode);
Begin
  TAstNode_Create(PAstNode(Self), $3);
  Self.Parent.VMT.Destory := TUnaryOpNode_Destroy;
  Self.Value := nil;
End;

Procedure TUnaryOpNode_Destroy(Self: PAstNode);
Begin
  If PUnaryOpNode(Self).Value <> nil Then
  Begin
    PUnaryOpNode(Self).Value.VMT.Destory(PUnaryOpNode(Self).Value);
    Dispose(PUnaryOpNode(Self).Value);
  End;
  TAstNode_Destroy(Self);
End;

End.
