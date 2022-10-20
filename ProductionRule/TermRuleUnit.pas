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
Function TermExpression4(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  ExprRuleUnit, LiteralNode, UnaryOpNode, VarRuleUnit;

// Term -> Var
Function TermExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  If Not VarRule(Parser, Ast) Then
  Begin
    Parser.Error := 'Number expected.';
    Result := False;
    Exit;
  End;
  Result := True;
End;

// Term -> number 
Function TermExpression4(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  If Not TParser_Term(Parser, eNum) Then
  Begin
    Parser.Error := 'Number expected.';
    Result := False;
    Exit;
  End;
  New(PLiteralNode(Ast));
  TLiteralNode_Create(PLiteralNode(Ast), eNumber,
    TParser_GetCurrentToken(Parser).Value);
  Result := True;
End;

Function TermRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  //Result := TParser_Prod(Parser, Ast, [@TermExpression1, @TermExpression2]);
  Result := TermExpression1(Parser, Ast) Or TermExpression2(Parser, Ast) Or
    TermExpression3(Parser, Ast) Or TermExpression4(Parser, Ast);
End;

// Term -> LParent Expr RParent
Function TermExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  If Not TParser_Term(Parser, eLParent) Then
  Begin
    Parser.Error := '( expected.';
    Ast := nil;
    Result := False;
    Exit;
  End;
  If Not ExprRuleUnit.ExprRule(Parser, Ast) Then
  Begin
    Parser.Error := 'Expression expected.';
    Ast := nil;
    Result := False;
    Exit;
  End;
  If Not TParser_Term(Parser, eRParent) Then
  Begin
    Parser.Error := ') expected.';
    Ast := nil;
    Result := False;
    Exit;
  End;
  Result := True;
  // Ast := Ast; // Ast => Expr's Ast
End;

// Term -> Not Term
Function TermExpression3(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mValue: PAstNode;
Begin
  Result := False;
  If Not TParser_Term(Parser, TTokenKind.eNot) Then
  Begin
    Parser.Error := 'Not expected.';
    Exit;
  End;
  If Not TermRule(Parser, mValue) Then
  Begin
    Parser.Error := 'Not Expression expected.';
    Exit;
  End;
  New(PUnaryOpNode(Ast));
  TUnaryOpNode_Create(PUnaryOpNode(Ast));
  PUnaryOpNode(Ast).OpType := eNot;
  PUnaryOpNode(Ast).Value := mValue;
  Result := True;
End;

End.
