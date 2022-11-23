Unit AssignStmtRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function AssignStmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function AssignStmtExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  ExprRuleUnit, VarRuleUnit, AssignNode, IdNode;

// AssignStmt -> Var ASSIGN Expr 
Function AssignStmtExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mLeftHandSide: PAstNode;
  mRightHandSide: PAstNode;
Begin
  If Not VarRule(Parser, mLeftHandSide) Then
  Begin
    Parser.Error := 'Variable expected.';
    Result := False;
    Exit;
  End;
  If Not TParser_Term(Parser, eAssign) Then
  Begin
    Parser.Error := ':= expected.';
    Result := False;
    Exit;
  End;
  If Not ExprRule(Parser, mRightHandSide) Then
  Begin
    Parser.Error := 'Expression expected.';
    Result := False;
    Exit;
  End;

  New(PAssignNode(Ast));
  TAssignNode_Create(PAssignNode(Ast));
  PAssignNode(Ast).LeftHandSide := mLeftHandSide;
  PAssignNode(Ast).RightHandSide := mRightHandSide;
  Result := True;
End;

Function AssignStmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := AssignStmtExpression1(Parser, Ast);
End;


End.
