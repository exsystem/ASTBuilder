Unit TermRuleRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function TermRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function TermRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  IdNode, GroupNode, RuleNode, TermExprRuleUnit;

// rule -> term Colon expr Semi
Function TermRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mName: String;
  mGroupNode: PAstNode;
Label
  S1, S2;
Begin
  S1:
    If TParser_Term(Parser, eTerm) Then
    Begin
      mName := TParser_GetCurrentToken(Parser).Value;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  If TParser_Term(Parser, TTokenKind.eColon) Then
  Begin
    // NOP
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  If TermExprRule(Parser, mGroupNode) Then
  Begin
    // NOP
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  If TParser_Term(Parser, eSemi) Then
  Begin
    TRuleNode_Create(PRuleNode(Ast));
    PRuleNode(Ast).Name := mName;
    PRuleNode(Ast).Expr := PGroupNode(mGroupNode);
  End
  Else
  Begin
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
