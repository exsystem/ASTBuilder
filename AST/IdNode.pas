Unit IdNode;

{$I define.inc}

Interface

Uses
  ASTNode, TypeDef;

Type
  PIdNode = ^TIdNode;

  TIdNode = Record
    Parent: TAstNode;
    Value: PTChar;
  End;

Procedure TIdNode_Create(Var Self: PIdNode; Value: PTChar);

Procedure TIdNode_Destroy(Self: PAstNode);

Procedure TIdNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTIdNode_AST: TAstNode_VMT;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

Procedure TIdNode_Create(Var Self: PIdNode; Value: PTChar);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self^.Parent.VMT := @mTIdNode_AST;

  Self^.Value := TCharStrNew(Value);
End;

Procedure TIdNode_Destroy(Self: PAstNode);
Begin
  FreeStr(PIdNode(Self)^.Value);
  TAstNode_Destroy(Self);
End;

Procedure TIdNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor^.Methods^.VisitId(Visitor, Self);
End;

Begin
  mTIdNode_AST.Destory := TIdNode_Destroy;
  mTIdNode_AST.Accept := TIdNode_Accept;
End.
