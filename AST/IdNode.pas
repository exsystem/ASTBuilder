Unit IdNode;

{$I define.inc}

Interface

Uses
  ASTNode;

Type
  PIdNode = ^TIdNode;

  TIdNode = Record
    Parent: TAstNode;
    Value: PChar;
  End;

Procedure TIdNode_Create(Var Self: PIdNode; Value: PChar);

Procedure TIdNode_Destroy(Self: PAstNode);

Procedure TIdNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTIdNode_AST: TAstNode_VMT;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtils;

Procedure TIdNode_Create(Var Self: PIdNode; Value: PChar);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self^.Parent.VMT := @mTIdNode_AST;

  Self^.Value := strnew(Value);
End;

Procedure TIdNode_Destroy(Self: PAstNode);
Begin
  FreeStr(PIdNode(Self)^.Value);
  TAstNode_Destroy(Self);
End;

Procedure TIdNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor^.VMT^.VisitId(Visitor, Self);
End;

Begin
  mTIdNode_AST.Destory := TIdNode_Destroy;
  mTIdNode_AST.Accept := TIdNode_Accept;
End.
