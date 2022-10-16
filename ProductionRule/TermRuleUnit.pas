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
Function TermExpression3(Parser: PParser; Out Ast: PAstNode): Boolean;

Implementation

Uses
  ExprRuleUnit, SignOpRuleUnit, LiteralNode, UnaryOpNode;

Function TermExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Var
  mSignNode: PAstNode;
  mLiteralNode: PAstNode;
Begin
  mSignNode := nil;
  SignOpRule(Parser, mSignNode);
  If Not TParser_Term(Parser, eNum) Then
  Begin
    Parser.Error := 'Number expected.';
    TUnaryOpNode_Destroy(PAstNode(mSignNode));
    Dispose(mSignNode);
    Ast := nil;
    Result := False;
    Exit;
  End;
  New(PLiteralNode(mLiteralNode));
  TLiteralNode_Create(PLiteralNode(mLiteralNode), eNumber,
    TParser_GetCurrentToken(Parser).Value);
  If mSignNode = nil Then
  Begin
    Ast := mLiteralNode;
  End
  Else
  Begin
    PUnaryOpNode(mSignNode).Value := mLiteralNode;
    Ast := mSignNode;
  End;
  Result := True;
End;

Function TermRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  //Result := TParser_Prod(Parser, Ast, [@TermExpression1, @TermExpression2]);
  Result := TermExpression1(Parser, Ast) Or TermExpression2(Parser, Ast) Or
    TermExpression3(Parser, Ast);
End;

Function TermExpression2(Parser: PParser; Out Ast: PAstNode): Boolean;
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

Function TermExpression3(Parser: PParser; Out Ast: PAstNode): Boolean;
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
