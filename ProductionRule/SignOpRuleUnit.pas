Unit SignOpRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function SignOpRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function SignOpExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  UnaryOpNode;

Function SignOpExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  New(PUnaryOpNode(Ast));
  TUnaryOpNode_Create(PUnaryOpNode(Ast));
  If TParser_Term(Parser, ePlus) Then
  Begin
    PUnaryOpNode(Ast).OpType := ePositive;
    Result := True;
    Exit;
  End;
  If TParser_Term(Parser, eMinus) Then
  Begin
    PUnaryOpNode(Ast).OpType := eNegative;
    Result := True;
    Exit;
  End;
  TUnaryOpNode_Destroy(Ast);
  Dispose(PUnaryOpNode(Ast));
  Ast := nil;
  Parser.Error := 'Sign operator expected.';
  Result := False;
End;

Function SignOpRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := SignOpExpression1(Parser, Ast);
End;

End.
