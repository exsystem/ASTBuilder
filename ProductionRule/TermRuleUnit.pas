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
Function TermExpression3(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  ExprRuleUnit, LiteralNode, UnaryOpNode;

Function TermExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mValue: String;
Begin
  mValue := '';
  If TParser_Term(Parser, ePlus) Or TParser_Term(Parser, eMinus) Then
  Begin
    If TParser_IsToken(Parser, eMinus) Then
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
  TLiteralNode_Create(PLiteralNode(Ast), eNumber, mValue);
End;

Function TermRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  //Result := TParser_Prod(Parser, Ast, [@TermExpression1, @TermExpression2]);
  Result := TermExpression1(Parser, Ast) Or TermExpression2(Parser, Ast) Or
    TermExpression3(Parser, Ast);
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

Function TermExpression3(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mNode: PUnaryOpNode;
Begin
  New(mNode);
  TUnaryOpNode_Create(mNode);
  mNode.OpType := eNot;
  Result := (TParser_Term(Parser, TTokenKind.eNot) And TermRule(Parser, mNode.Value));
  If Not Result Then
  Begin
    Parser.Error := 'Not Expression expected.';
    TUnaryOpNode_Destroy(PAstNode(mNode));
    Dispose(mNode);
    Exit;
  End;
  Ast := PAstNode(mNode);
End;

End.
