Unit TermRuleNode;

{$I define.inc}

Interface

Uses
  ASTNode, NFA;

Type
  PPTermRuleNode = ^PTermRuleNode;
  PTermRuleNode = ^TTermRuleNode;

  TTermRuleNode = Record
    Parent: TAstNode;
    Name: PChar;
    Nfa: PNfa;
  End;

Procedure TTermRuleNode_Create(Var Self: PTermRuleNode);

Procedure TTermRuleNode_Destroy(Self: PAstNode);

Procedure TTermRuleNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTTermRuleNode_AST: TAstNode_VMT;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StringUtils;

Procedure TTermRuleNode_Create(Var Self: PTermRuleNode);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT := @mTTermRuleNode_AST;
  Self.Name := strnew('');
  Self.Nfa := nil;
End;

Procedure TTermRuleNode_Destroy(Self: PAstNode);
Begin
  If PTermRuleNode(Self).Nfa <> nil Then // only for non-empty rule.
  Begin
    TNfa_Destroy(PTermRuleNode(Self).Nfa);
  End;
  FreeStr(PTermRuleNode(Self).Name);
  TAstNode_Destroy(Self);
End;

Procedure TTermRuleNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitTermRule(Visitor, Self);
End;

Begin
  mTTermRuleNode_AST.Destory := TTermRuleNode_Destroy;
  mTTermRuleNode_AST.Accept := TTermRuleNode_Accept;
End.
