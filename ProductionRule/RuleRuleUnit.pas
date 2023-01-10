Unit RuleRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function RuleRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function RuleRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, List, IdNode, GroupNode, RuleNode, ExprRuleUnit;

// rule -> id Colon expr Semi 
Function RuleRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mIdNode: PAstNode;
  mGroupNode: PAstNode;
Label
  S1, S2;
Begin
  S1:
    If TParser_Term(Parser, eId) Then
    Begin
      TIdNode_Create(PIdNode(mIdNode), TParser_GetCurrentToken(Parser).Value);
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
  If ExprRule(Parser, mGroupNode) Then
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
    PRuleNode(Ast).Id := PIdNode(mIdNode);
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

Function RuleRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := RuleRuleExpression1(Parser, Ast);
End;

End.
