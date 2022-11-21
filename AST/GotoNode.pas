Unit GotoNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Const
  CNodeType = Byte($05);

Type
  PGotoNode = ^TGotoNode;

  TGotoNode = Record
    Parent: TAstNode;
    LabelName: String;
  End;

Procedure TGotoNode_Create(Self: PGotoNode; LabelName: String);
Procedure TGotoNode_Destroy(Self: PAstNode);

Implementation

Procedure TGotoNode_Create(Self: PGotoNode; LabelName: String);
Begin
  TAstNode_Create(PAstNode(Self), CNodeType);
  Self.Parent.VMT.Destory := TGotoNode_Destroy;
  Self.LabelName := LabelName;
End;

Procedure TGotoNode_Destroy(Self: PAstNode);
Begin
  TAstNode_Destroy(Self);
End;

End.
