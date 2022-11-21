Unit EmptyStmtRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, ASTNode;

Function EmptyStmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Function EmptyStmtRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := True;
End;

End.
