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
  TypeDef, List, GrmrNode, TrmRNode, RuleNode, RRUnit, OptRUnit,
  TRSRUNIT, GLEXER, GPARSER;

{ grammar -> ( Options LCurlyBrack option* RCurlyBrack ) ? rule* termRules }
Function GrammarRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS2, mSavePointS3: TSize;
  mRuleNode: PAstNode;
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
    mSavePointS3 := Parser^.FCurrentToken;
  If RuleRule(Parser, mRuleNode) Then
  Begin
    TList_PushBack(PGrammarNode(Ast)^.Rules, @mRuleNode);
    Goto S3;
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS3;
    Result := True;
    Goto S4;
  End;
  S4:
    If TermRules(Parser, Ast) Then
    Begin
      Result := True;
      Exit;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
End;

Function GrammarRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := GrammarRuleExpression1(Parser, Ast);
End;

End.
