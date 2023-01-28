Unit TermRuleNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode, NFA;

Type
  PPTermRuleNode = ^PTermRuleNode;
  PTermRuleNode = ^TTermRuleNode;

  TTermRuleNode = Record
    Parent: TAstNode;
    Name: String;
    Nfa: PNfa;
  End;

Procedure TTermRuleNode_Create(Var Self: PTermRuleNode);

Procedure TTermRuleNode_Destroy(Self: PAstNode);

Procedure TTermRuleNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTTermRuleNode_AST: TAstNode_VMT;

Implementation

Procedure TTermRuleNode_Create(Var Self: PTermRuleNode);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT := @mTTermRuleNode_AST;
End;

Procedure TTermRuleNode_Destroy(Self: PAstNode);
Begin
  If PTermRuleNode(Self).Nfa <> nil Then // only for non-empty rule.
  Begin
    TNfa_Destroy(PTermRuleNode(Self).Nfa);
  End;
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
