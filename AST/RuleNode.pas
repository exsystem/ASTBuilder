Unit RuleNode;

{$I define.inc}

Interface

Uses
  ASTNode, IdNode, GrpNode, TypeDef;

Type
  PPRuleNode = ^PRuleNode;
  PRuleNode = ^TRuleNode;

  TRuleNode = Record
    Parent: TAstNode;
    Id: TNonTermRuleId;
    Expr: PGroupNode;
  End;

Procedure TRuleNode_Create(Var Self: PRuleNode);

Procedure TRuleNode_Destroy(Self: PAstNode);

Procedure TRuleNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTRuleNode_AST: TAstNode_VMT;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF};

Procedure TRuleNode_Create(Var Self: PRuleNode);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self^.Parent.VMT := @mTRuleNode_AST;
  Self^.Id := 0;
End;

Procedure TRuleNode_Destroy(Self: PAstNode);
Begin
  If PRuleNode(Self)^.Expr <> nil Then { only for non-empty rule. }
  Begin
    TGroupNode_Destroy(PAstNode(PRuleNode(Self)^.Expr));
    Dispose(PRuleNode(Self)^.Expr);
  End;
  TAstNode_Destroy(Self);
End;

Procedure TRuleNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor^.Methods^.VisitRule(Visitor, Self);
End;

Begin
  mTRuleNode_AST.Destory := TRuleNode_Destroy;
  mTRuleNode_AST.Accept := TRuleNode_Accept;
End.
