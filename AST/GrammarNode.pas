Unit GrammarNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode, List;

Type
  PGrammarNode = ^TGrammarNode;

  TGrammarNode = Record
    Parent: TAstNode;
    Rules: PList; // Of PRuleNode
    TermRules: PList; // Of PTermRuleNode 
  End;

Procedure TGrammarNode_Create(Var Self: PGrammarNode);
Procedure TGrammarNode_Destroy(Self: PAstNode);
Procedure TGrammarNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTGrammarNode_VMT: TAstNode_VMT;

Implementation

Uses
  TypeDef, RuleNode, TermRuleNode;

Procedure TGrammarNode_Create(Var Self: PGrammarNode);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT := @mTGrammarNode_VMT;

  Self.Rules := TList_Create(SizeOf(PRuleNode), 1);
  Self.TermRules := TList_Create(SizeOf(PTermRuleNode), 1);
End;

Procedure TGrammarNode_Destroy(Self: PAstNode);
Var
  I: TSize;
  mElem: PAstNode;
Begin
  If PGrammarNode(Self).Rules.Size > 0 Then
  Begin
    For I := 0 To PGrammarNode(Self).Rules.Size - 1 Do
    Begin
      mElem := PPAstNode(TList_Get(PGrammarNode(Self).Rules, I))^;
      mElem.VMT.Destory(mElem);
      Dispose(mElem);
    End;
  End;
  TList_Destroy(PGrammarNode(Self).Rules);
  If PGrammarNode(Self).TermRules.Size > 0 Then
  Begin
    For I := 0 To PGrammarNode(Self).TermRules.Size - 1 Do
    Begin
      mElem := PPAstNode(TList_Get(PGrammarNode(Self).TermRules, I))^;
      mElem.VMT.Destory(mElem);
      Dispose(mElem);
    End;
  End;
  TList_Destroy(PGrammarNode(Self).TermRules);
  TAstNode_Destroy(Self);
End;

Procedure TGrammarNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitGrammar(Visitor, Self);
End;

Begin
  mTGrammarNode_VMT.Destory := TGrammarNode_Destroy;
  mTGrammarNode_VMT.Accept := TGrammarNode_Accept;
End.
