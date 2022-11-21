Unit GotoStmtRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function GotoStmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function GotoStmtExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  ExprRuleUnit, GotoNode;

// GotoStmt -> GOTO ID 
Function GotoStmtExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  If Not TParser_Term(Parser, eGoto) Then
  Begin
    Parser.Error := 'Goto expected.';
    Result := False;
    Exit;
  End;
  If Not TParser_Term(Parser, eId) Then
  Begin
    Parser.Error := 'Id expected.';
    Result := False;
    Exit;
  End;

  New(PGotoNode(Ast));
  TGotoNode_Create(PGotoNode(Ast), TParser_GetCurrentToken(Parser).Value);
  Result := True;
End;

Function GotoStmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := GotoStmtExpression1(Parser, Ast);
End;

End.
