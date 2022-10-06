Unit TermRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function TermRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Function TermExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Function TermExpression2(Parser: PParser; Out Ast: PAstNode): Boolean;

Implementation

Uses
  ExprRuleUnit, LiteralNode, List;

Function TermExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := TParser_Term(Parser, TTokenKind.eNum);
  If Not Result Then
  Begin
    Exit;
  End;
  Ast := TLiteralNode_Create(TLiteralType.eInteger,
    TParser_GetCurrentToken(Parser).Value);
End;

Function TermRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := TParser_Prod(Parser, Ast, [@TermExpression1, @TermExpression2]);
  //Result := TermExpression1(Parser, Ast) Or TermExpression2(Parser, Ast);
End;

Function TermExpression2(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := (TParser_Term(Parser, TTokenKind.eLParent) And
    ExprRuleUnit.ExprRule(Parser, Ast) And TParser_Term(Parser, TTokenKind.eRParent));
  If Not Result Then
  Begin
    Exit;
  End;
  // Ast := Ast; // Ast => Expr's Ast
End;

End.
