{ Unit TermRulesRuleUnit; }
Unit TRSRUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, ASTNode;

Function TermRules(Parser: PParser; Var Ast: PAstNode): Boolean;
Function TermRulesExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, IdNode, GrpNode, TrmRNode, TERUnit, TRRUNIT, GRMRNODE, NFA,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil, GLEXER, GPARSER;

{ termRules -> termRule* ( Mode Id Semi termRule* )* }
Function TermRulesExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS1, mSavePointS2, mSavePointS3: TSize;
  mTermRuleNode: PAstNode;
  mMode: PChar;
Label
  S1, S2, S3;
Begin
  S1:
    mSavePointS1 := Parser^.FCurrentToken;
  Result := True;
  If TermRule(Parser, mTermRuleNode) Then
  Begin
    TGrammarNode_AddTermRule(PGrammarNode(Ast), '', PTermRuleNode(mTermRuleNode));
    Goto S1;
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS1;
    Goto S2;
  End;
  S2:
    mSavePointS2 := Parser^.FCurrentToken;
  If TGrammarParser_Term(Parser, eMode) Then
  Begin
    { NOP }
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS2;
    Exit;
  End;
  If TGrammarParser_Term(Parser, eId) Then
  Begin
    mMode := StrNew(TParser_GetCurrentToken(Parser)^.Value);
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS2;
    Exit;
  End;
  If TGrammarParser_Term(Parser, eSemi) Then
  Begin
    { NOP }
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS2;
    FreeStr(mMode);
    Exit;
  End;
  S3:
    mSavePointS3 := Parser^.FCurrentToken;
  If TermRule(Parser, mTermRuleNode) Then
  Begin
    TGrammarNode_AddTermRule(PGrammarNode(Ast), mMode, PTermRuleNode(mTermRuleNode));
    Goto S3;
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS3;
    FreeStr(mMode);
    Goto S2;
  End;
End;

Function TermRules(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := TermRulesExpression1(Parser, Ast);
End;

End.
