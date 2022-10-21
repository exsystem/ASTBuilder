Unit AssignNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PAssignNode = ^TAssignNode;

  TAssignNode = Record
    Parent: TAstNode;
    LeftHandSide: PASTNode;
    RightHandSide: PASTNode;
  End;

Procedure TAssignNode_Create(Self: PAssignNode);
Procedure TAssignNode_Destroy(Self: PAstNode);

Implementation

Procedure TAssignNode_Create(Self: PAssignNode);
Begin
  TAstNode_Create(PAstNode(Self), $8);
  Self.Parent.VMT.Destory := TAssignNode_Destroy;
  Self.LeftHandSide:= nil;
  Self.RightHandSide:= nil;
End;

Procedure TAssignNode_Destroy(Self: PAstNode);
Begin
  If PAssignNode(Self).LeftHandSide<> nil Then
  Begin
    PAssignNode(Self).LeftHandSide.VMT.Destory(PAssignNode(Self).LeftHandSide);
    Dispose(PAssignNode(Self).LeftHandSide);
  End;
  If PAssignNode(Self).RightHandSide<> nil Then
  Begin
    PAssignNode(Self).RightHandSide.VMT.Destory(PAssignNode(Self).RightHandSide);
    Dispose(PAssignNode(Self).RightHandSide);
  End;
  TAstNode_Destroy(Self);
End;

End.
