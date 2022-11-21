Unit SimpleStmtRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function SimpleStmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function SimpleStmtExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Function SimpleStmtExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;
Function SimpleStmtExpression3(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  AssignStmtRuleUnit, GotoStmtRuleUnit, EmptyStmtRuleUnit;

// SimpleStmt -> AssignStmt 
Function SimpleStmtExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := AssignStmtRule(Parser, Ast);
End;

// SimpleStmt -> GotoStmt 
Function SimpleStmtExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := GotoStmtRule(Parser, Ast);
End;

// SimpleStmt -> EmptyStmt 
Function SimpleStmtExpression3(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := EmptyStmtRule(Parser, Ast);
End;

// TODO: SimpleStmt -> ProcStmt

Function SimpleStmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := SimpleStmtExpression1(Parser, Ast) Or SimpleStmtExpression2(Parser, Ast) Or
    SimpleStmtExpression3(Parser, Ast);
End;

End.
