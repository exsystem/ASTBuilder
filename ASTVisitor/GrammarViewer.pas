Unit GrammarViewer;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PAstViewer = ^TAstViewer;

  TAstViewer = Record
    Parent: TAstVisitor;
  End;

Procedure TAstViewer_Create(Var Self: PAstViewer);
Procedure TAstViewer_Destroy(Self: PAstVisitor);
Procedure TAstViewer_VisitId(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitTerm(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitGroup(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitRule(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitGrammar(Self: PAstVisitor; Node: PAstNode);

Implementation

Uses
  IdNode, TermNode, GroupNode, RuleNode, GrammarNode;

Var
  mTAstViewer_VMT: TAstVisitor_VMT;

Procedure TAstViewer_Create(Var Self: PAstViewer);
Begin
  New(Self); // Final
  TAstVisitor_Create(PAstVisitor(Self));
  Self.Parent.VMT := @mTAstViewer_VMT;
End;

Procedure TAstViewer_Destroy(Self: PAstVisitor);
Begin
  TAstVisitor_Destroy(Self);
End;

Procedure TAstViewer_VisitId(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PIdNode;
Begin
  mNode := PIdNode(Node);
  Write(mNode.Value);
End;

Procedure TAstViewer_VisitTerm(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PTermNode;
Begin
  mNode := PTermNode(Node);
  Write(mNode.Value);
End;

Procedure TAstViewer_VisitGroup(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PGroupNode;
Begin
  mNode := PGroupNode(Node);
  Write(mNode.Terms.Size);
End;

Procedure TAstViewer_VisitRule(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PRuleNode;
Begin
  mNode := PRuleNode(Node);
  Write(mNode.Id.Value);
End;

Procedure TAstViewer_VisitGrammar(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PGrammarNode;
Begin
  mNode := PGrammarNode(Node);
  Write(mNode.Rules.Size);
End;

Begin
  mTAstViewer_VMT.Destory := TAstViewer_Destroy;
  mTAstViewer_VMT.VisitId := TAstViewer_VisitId;
  mTAstViewer_VMT.VisitTerm := TAstViewer_VisitTerm;
  mTAstViewer_VMT.VisitGroup := TAstViewer_VisitGroup;
  mTAstViewer_VMT.VisitRule:= TAstViewer_VisitRule;
  mTAstViewer_VMT.VisitGrammar := TAstViewer_VisitGrammar;
End.
