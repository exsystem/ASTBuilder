Unit GrammarViewer;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode, TypeDef;

Type
  PAstViewer = ^TAstViewer;

  TAstViewer = Record
    Parent: TAstVisitor;
    Level: TSize;
  End;

Procedure TAstViewer_Create(Var Self: PAstViewer);

Procedure TAstViewer_Destroy(Self: PAstVisitor);

Procedure TAstViewer_VisitId(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitTerm(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitGroup(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitRule(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitGrammar(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_WriteLn(Self: PAstVisitor; Content: String);

Procedure TAstViewer_Indent(Self: PAstVisitor);

Procedure TAstViewer_Deindent(Self: PAstVisitor);

Implementation

Uses
  List, IdNode, TermNode, GroupNode, RuleNode, GrammarNode;

Var
  mTAstViewer_VMT: TAstVisitor_VMT;

Procedure TAstViewer_Create(Var Self: PAstViewer);
Begin
  New(Self); // Final
  TAstVisitor_Create(PAstVisitor(Self));
  Self.Parent.VMT := @mTAstViewer_VMT;
  Self.Level := 0;
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
  TAstViewer_WriteLn(Self, 'Non-Terminal: ' + mNode.Value);
End;

Procedure TAstViewer_VisitTerm(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PTermNode;
Begin
  mNode := PTermNode(Node);
  TAstViewer_WriteLn(Self, 'Terminal: ' + mNode.Value);
End;

Procedure TAstViewer_VisitGroup(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PGroupNode;
  I: TSize;
  mItem: PAstNode;
  mGroupType: String;
  mTermsRelationship: String;
Begin
  mNode := PGroupNode(Node);
  Case mNode.GroupType Of
    TGroupType.eGroup:
      mGroupType := 'Group';
    TGroupType.eOptional:
      mGroupType := 'Optional';
    TGroupType.eMultiple:
      mGroupType := 'Multiple';
  End;
  If mNode.IsAlternational Then
  Begin
    mTermsRelationship := ' Alternation';
  End;

  TAstViewer_WriteLn(Self, mGroupType + mTermsRelationship + ':');

  For I := 0 To mNode.Terms.Size - 1 Do
  Begin
    mItem := PPAstNode(TList_Get(mNode.Terms, I))^;
    TAstViewer_Indent(Self);
    If mItem = nil Then
    Begin
      TAstViewer_WriteLn(Self, '<empty term>');
    End
    Else
    Begin
      mItem.VMT.Accept(mItem, Self);
    End;
    TAstViewer_Deindent(Self);
  End;
End;

Procedure TAstViewer_VisitRule(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PRuleNode;
Begin
  mNode := PRuleNode(Node);
  TAstViewer_WriteLn(Self, mNode.Id.Value + ':');
  TAstViewer_Indent(Self);
  If mNode.Expr = nil Then
  Begin
    TAstViewer_WriteLn(Self, '<empty rule>');
  End
  Else
  Begin
    mNode.Expr.Parent.VMT.Accept(PAstNode(mNode.Expr), Self);
  End;
  TAstViewer_Deindent(Self);
End;

Procedure TAstViewer_VisitGrammar(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PGrammarNode;
  I: TSize;
  mItem: PAstNode;
Begin
  mNode := PGrammarNode(Node);
  TAstViewer_WriteLn(Self, 'Grammar:');
  If mNode.Rules.Size <> 0 Then
  Begin
    For I := 0 To mNode.Rules.Size - 1 Do
    Begin
      mItem := PPAstNode(TList_Get(mNode.Rules, I))^;
      TAstViewer_Indent(Self);
      mItem.VMT.Accept(mItem, Self);
      TAstViewer_Deindent(Self);
    End;
  End;
End;

Procedure TAstViewer_WriteLn(Self: PAstVisitor; Content: String);
Var
  I: TSize;
Begin
  If PAstViewer(Self).Level > 0 Then
  Begin
    For I := 0 To PAstViewer(Self).Level - 1 Do
    Begin
      Write('  ');
    End;
  End;
  Writeln(Content);
End;

Procedure TAstViewer_Indent(Self: PAstVisitor);
Begin
  Inc(PAstViewer(Self).Level);
End;

Procedure TAstViewer_Deindent(Self: PAstVisitor);
Begin
  Dec(PAstViewer(Self).Level);
End;

Begin
  mTAstViewer_VMT.Destory := TAstViewer_Destroy;
  mTAstViewer_VMT.VisitId := TAstViewer_VisitId;
  mTAstViewer_VMT.VisitTerm := TAstViewer_VisitTerm;
  mTAstViewer_VMT.VisitGroup := TAstViewer_VisitGroup;
  mTAstViewer_VMT.VisitRule := TAstViewer_VisitRule;
  mTAstViewer_VMT.VisitGrammar := TAstViewer_VisitGrammar;

End.
