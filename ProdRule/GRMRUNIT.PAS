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
  TypeDef, List, GrmrNode, TrmRNode, RuleNode, RRUnit, TRRUnit, OptRUnit, GLEXER, GPARSER;

{ grammar -> ( Options LCurlyBrack option* RCurlyBrack ) ? rule* termRule* }
Function GrammarRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS1, mSavePointS2: TSize;
  mRuleNode: PAstNode;
  mTermRuleNode: PAstNode;
Label
  S1, S2, S3, S4;
Begin
  TGrammarNode_Create(PGrammarNode(Ast));
  S1:
  If TGrammarParser_Term(Parser, eOptions) Then
  Begin
    { NOP }
  End
  Else
  Begin
    Goto S3;
  End;
  If TGrammarParser_Term(Parser, eLCurlyBracket) Then
  Begin
    { NOP } 
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  S2:
    mSavePointS2 := Parser^.FCurrentToken;
  If OptionRule(Parser, Ast) Then
  Begin
    Goto S2;
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS2;
  End;
  If TGrammarParser_Term(Parser, eRCurlyBracket) Then
  Begin
    { NOP }
  End
  Else
  Begin
    Result := False;
    Exit;
  End;

  S3:
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
  S4:
    Goto S3;
End;

Function GrammarRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := GrammarRuleExpression1(Parser, Ast);
End;

End.
