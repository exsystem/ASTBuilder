Unit IdNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PIdNode = ^TIdNode;

  TIdNode = Record
    Parent: TAstNode;
    Value: String;
  End;

Procedure TIdNode_Create(Var Self: PIdNode; Value: String);

Procedure TIdNode_Destroy(Self: PAstNode);

Procedure TIdNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTIdNode_AST: TAstNode_VMT;

Implementation

Procedure TIdNode_Create(Var Self: PIdNode; Value: String);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT := @mTIdNode_AST;

  Self.Value := Value;
End;

Procedure TIdNode_Destroy(Self: PAstNode);
Begin
  TAstNode_Destroy(Self);
End;

Procedure TIdNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitId(Visitor, Self);
End;

Begin
  mTIdNode_AST.Destory := TIdNode_Destroy;
  mTIdNode_AST.Accept := TIdNode_Accept;
End.
