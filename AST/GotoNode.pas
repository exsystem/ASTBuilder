Unit GotoNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PGotoNode = ^TGotoNode;

  TGotoNode = Record
    Parent: TAstNode;
    LabelName: String;
  End;

Procedure TGotoNode_Create(Self: PGotoNode; LabelName: String);
Procedure TGotoNode_Destroy(Self: PAstNode);
Procedure TGotoNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Implementation

Procedure TGotoNode_Create(Self: PGotoNode; LabelName: String);
Begin
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT.Destory := TGotoNode_Destroy;
  Self.Parent.VMT.Accept := TGotoNode_Accept;
  Self.LabelName := LabelName;
End;

Procedure TGotoNode_Destroy(Self: PAstNode);
Begin
  TAstNode_Destroy(Self);
End;

Procedure TGotoNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitGoto(Visitor, Self);
End;

End.
