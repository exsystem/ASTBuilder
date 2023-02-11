Unit TermRuleRuleUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, ASTNode;

Function TermRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function TermRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  IdNode, GroupNode, TermRuleNode, TermExprRuleUnit, NFA,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StringUtils;

// termRule -> term Colon termExpr Semi
Function TermRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mName: PChar;
  mNfa: PNfa;
Label
  S1, S2;
Begin
  S1:
    If TParser_Term(Parser, eTerm) Then
    Begin
      mName := strnew(TParser_GetCurrentToken(Parser).Value);
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  If TParser_Term(Parser, TGrammarTokenKind.eColon) Then
  Begin
    // NOP
  End
  Else
  Begin
    FreeStr(mName);
    Result := False;
    Exit;
  End;
  If TermExprRule(Parser, mNfa) Then
  Begin
    // NOP
  End
  Else
  Begin
    FreeStr(mName);
    Result := False;
    Exit;
  End;
  If TParser_Term(Parser, eSemi) Then
  Begin
    TTermRuleNode_Create(PTermRuleNode(Ast));
    FreeStr(PTermRuleNode(Ast).Name);
    PTermRuleNode(Ast).Name := mName;
    PTermRuleNode(Ast).Nfa := mNfa;
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
