Unit StringNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PStringNode = ^TStringNode;

  TStringNode = Record
    Parent: TAstNode;
    Value: String;
  End;

Procedure TStringNode_Create(Var Self: PStringNode; Value: String);

Procedure TStringNode_Destroy(Self: PAstNode);

Procedure TStringNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTStringNode_AST: TAstNode_VMT;

Implementation

Procedure TStringNode_Create(Var Self: PStringNode; Value: String);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT := @mTStringNode_AST;

  Self.Value := Value;
End;

Procedure TStringNode_Destroy(Self: PAstNode);
Begin
  TAstNode_Destroy(Self);
End;

Procedure TStringNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitString(Visitor, Self);
End;

Begin
  mTStringNode_AST.Destory := TStringNode_Destroy;
  mTStringNode_AST.Accept := TStringNode_Accept;
End.
