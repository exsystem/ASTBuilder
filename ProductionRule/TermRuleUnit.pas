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
  ExprRuleUnit, LiteralNode, UnaryOpNode;

Function TermExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
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
    Ast := nil;
    Exit;
  End;
  mValue := mValue + TParser_GetCurrentToken(Parser).Value;

  New(PLiteralNode(Ast));
  TLiteralNode_Create(PLiteralNode(Ast), eNumber, mValue);
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
