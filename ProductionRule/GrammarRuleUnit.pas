Unit GrammarRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function GrammarRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function GrammarRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, List, GrammarNode, RuleNode, RuleRuleUnit;

// grammar -> rule* 
Function GrammarRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS1: TSize;
  mRuleNode: PAstNode;
Label
  S1, S2;
Begin
  TGrammarNode_Create(PGrammarNode(Ast));
  S1:
    mSavePointS1 := Parser.FCurrentToken;
  If RuleRule(Parser, mRuleNode) Then
  Begin
    TList_PushBack(PGrammarNode(Ast).Rules, @mRuleNode);
  End
  Else
  Begin
    Parser.FCurrentToken := mSavePointS1;
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
