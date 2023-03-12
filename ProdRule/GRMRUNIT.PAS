{ Unit GrammarRuleUnit; }
Unit GrmRUnit;

{$I define.inc}

Interface

Uses
  Parser, ASTNode;

Function GrammarRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function GrammarRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, List, GrmrNode, RuleNode, RRUnit, TRRUnit;

{ grammar -> rule* termRule* }
Function GrammarRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS1: TSize;
  mRuleNode: PAstNode;
  mTermRuleNode: PAstNode;
Label
  S1, S2;
Begin
  TGrammarNode_Create(PGrammarNode(Ast));
  S1:
    mSavePointS1 := Parser^.FCurrentToken;
  If RuleRule(Parser, mRuleNode) Then
  Begin
    TList_PushBack(PGrammarNode(Ast)^.Rules, @mRuleNode);
  End
  Else If TermRule(Parser, mTermRuleNode) Then
  Begin
    TList_PushBack(PGrammarNode(Ast)^.TermRules, @mTermRuleNode);
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS1;
    Result := True;
    Exit;
  End;
  S2:
    Goto S1;
End;

Function GrammarRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := GrammarRuleExpression1(Parser, Ast);
End;

End.