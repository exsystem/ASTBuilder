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
  IdNode, GroupNode, TermRuleNode, TermExprRuleUnit, NFA;

// termRule -> term Colon termExpr Semi
Function TermRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mName: String;
  mNfa: PNfa;
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
  If TermExprRule(Parser, mNfa) Then
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
    TTermRuleNode_Create(PTermRuleNode(Ast));
    PTermRuleNode(Ast).Name := mName;
    PTermRuleNode(Ast).Nfa := mNfa;
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
