{ Unit TermRuleRuleUnit; }
Unit TRRUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, ASTNode;

Function TermRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function TermRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  IdNode, GrpNode, TrmRNode, GRMRNODE, TERUnit, ASRUNIT, NFA,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil, GLEXER, GPARSER;

{ termRule -> term Colon termExpr (Arrow actions)? Semi }
Function TermRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mName: PChar;
  mNfa: PNfa;
Label
  S1, S2, S3;
Begin
  S1:
    If TGrammarParser_Term(Parser, eTerm) Then
    Begin
      mName := strnew(TParser_GetCurrentToken(Parser)^.Value);
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  If TGrammarParser_Term(Parser, eColon) Then
  Begin
    { NOP }
  End
  Else
  Begin
    FreeStr(mName);
    Result := False;
    Exit;
  End;
  If TermExprRule(Parser, mNfa) Then
  Begin
    { NOP }
  End
  Else
  Begin
    FreeStr(mName);
    Result := False;
    Exit;
  End;
  TTermRuleNode_Create(PTermRuleNode(Ast));
  PTermRuleNode(Ast)^.TermRuleId :=
    TGrammarNode_RegisterTermRule(PGrammarNode(PGrammarParser(Parser)^.Ast), mName);
  FreeStr(mName);
  PTermRuleNode(Ast)^.Nfa := mNfa;
  If TGrammarParser_Term(Parser, eArrow) Then
  Begin
    {NOP}
  End
  Else
  Begin
    Goto S2;
  End;
  If ActionsRule(Parser, Ast) Then
  Begin
    {NOP}
  End
  Else
  Begin
    TTermRuleNode_Destroy(Ast);
    Dispose(PTermRuleNode(Ast));
    Result := False;
    Exit;
  End;
  S2:
    If TGrammarParser_Term(Parser, eSemi) Then
    Begin
      {NOP}
    End
    Else
    Begin
      TTermRuleNode_Destroy(Ast);
      Dispose(PTermRuleNode(Ast));
      Result := False;
      Exit;
    End;
  S3:
    Result := True;
End;

Function TermRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := TermRuleExpression1(Parser, Ast);
End;

End.
