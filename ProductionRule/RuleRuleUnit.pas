Unit RuleRuleUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, ASTNode;

Function RuleRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function RuleRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  IdNode, GroupNode, RuleNode, ExprRuleUnit,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StringUtils;

// rule -> id Colon expr Semi 
Function RuleRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mName: PChar;
  mGroupNode: PAstNode;
Label
  S1, S2;
Begin
  S1:
    If TParser_Term(Parser, eId) Then
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
  If ExprRule(Parser, mGroupNode) Then
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
    TRuleNode_Create(PRuleNode(Ast));
    FreeStr(PRuleNode(Ast).Name);
    PRuleNode(Ast).Name := mName;
    PRuleNode(Ast).Expr := PGroupNode(mGroupNode);
  End
  Else
  Begin
    FreeStr(mName);
    Result := False;
    Exit;
  End;
  S2:
    Result := True;
End;

Function RuleRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := RuleRuleExpression1(Parser, Ast);
End;

End.
