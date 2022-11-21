Unit UnlabelledStmtRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function UnlabelledStmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function UnlabelledStmtExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
// Function UnlabelledStmtExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  SimpleStmtRuleUnit; 

// UnlabelledStmt -> SimpleStmt 
Function UnlabelledStmtExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := SimpleStmtRule(Parser, Ast);
End;

// UnlabelledStmt -> StructuredStmt 
// Function UnlabelledStmtExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;
// Begin
  // Result := StructuredStmtRule(Parser, Ast);
// End;

Function UnlabelledStmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := UnlabelledStmtExpression1(Parser, Ast) {Or
    UnlabelledStmtExpression2(Parser, Ast)};
End;

End.
