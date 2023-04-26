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
  IdNode, GrpNode, TrmRNode, TERUnit, NFA,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

{ termRule -> term Colon termExpr skip? Semi }
Function TermRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mName: PChar;
  mNfa: PNfa;
  mSkipped: Boolean;
Label
  S1, S2;
Begin
  S1:
    If TParser_TermByGrammarTokenKind(Parser, eTerm) Then
    Begin
      mName := strnew(TParser_GetCurrentToken(Parser)^.Value);
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  If TParser_TermByGrammarTokenKind(Parser, eColon) Then
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
  mSkipped := TParser_TermByGrammarTokenKind(Parser, eSkip);
  If TParser_TermByGrammarTokenKind(Parser, eSemi) Then
  Begin
    TTermRuleNode_Create(PTermRuleNode(Ast));
    FreeStr(PTermRuleNode(Ast)^.Name);
    PTermRuleNode(Ast)^.Name := mName;
    PTermRuleNode(Ast)^.Nfa := mNfa;
    PTermRuleNode(Ast)^.Skipped := mSkipped;
  End
  Else
  Begin
    TNfa_Destroy(mNfa);
    FreeStr(mName);
    Result := False;
    Exit;
  End;
  S2:
    Result := True;
End;

Function TermRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := TermRuleExpression1(Parser, Ast);
End;

End.
