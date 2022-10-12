Unit TermRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function TermRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function TermExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Function TermExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  ExprRuleUnit, LiteralNode;

Function TermExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mValue: String;
Begin
  If TParser_Term(Parser, eAdd) Or TParser_Term(Parser, eSub) Then
  Begin
    If TParser_IsToken(Parser, eSub) Then
    Begin
      mValue := '-';
      // mValue := TParser_GetCurrentToken(Parser).Value; // it must be '-' actually.
    End;
  End;
  Result := TParser_Term(Parser, eNum);
  If Not Result Then
  Begin
    Parser.Error := 'Number expected.';
    Exit;
  End;
  mValue := mValue + TParser_GetCurrentToken(Parser).Value;

  New(PLiteralNode(Ast));
  TLiteralNode_Create(PLiteralNode(Ast), eInteger, mValue);
End;

Function TermRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  //Result := TParser_Prod(Parser, Ast, [@TermExpression1, @TermExpression2]);
  Result := TermExpression1(Parser, Ast) Or TermExpression2(Parser, Ast);
End;

Function TermExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := (TParser_Term(Parser, eLParent) And ExprRuleUnit.ExprRule(Parser, Ast) And
    TParser_Term(Parser, eRParent));
  If Not Result Then
  Begin
    Parser.Error := 'Expression expected.';
    Exit;
  End;
  // Ast := Ast; // Ast => Expr's Ast
End;

End.
