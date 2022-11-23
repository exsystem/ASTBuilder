Unit StmtRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function StmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function StmtExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Function StmtExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  UnlabelledStmtRuleUnit, LabelledStmtNode, TypeDef;

// Stmt -> Id : UnlabelledStmt 
Function StmtExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mLabel: String;
  mStmt: PAstNode;
  mSavePoint: TSize;
Begin
  mSavePoint := Parser.FCurrentToken;
  If Not TParser_Term(Parser, eId) Then
  Begin
    Parser.Error := 'Id expected.';
    Result := False;
    Exit;
  End;
  mLabel := TParser_GetCurrentToken(Parser).Value;
  If Not TParser_Term(Parser, eColon) Then
  Begin
    Parser.Error := ': expected.';
    Parser.FCurrentToken := mSavePoint;
    Result := False;
    Exit;
  End;
  If Not UnlabelledStmtRule(Parser, mStmt) Then
  Begin
    Parser.FCurrentToken := mSavePoint;
    Result := False;
    Exit;
  End;

  New(PLabelledStmtNode(Ast));
  TLabelledStmtNode_Create(PLabelledStmtNode(Ast), mLabel, mStmt);
  Result := True;
End;

// Stmt -> UnlabelledStmt 
Function StmtExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := UnlabelledStmtRule(Parser, Ast);
End;

Function StmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := StmtExpression1(Parser, Ast) Or StmtExpression2(Parser, Ast);
End;

End.
