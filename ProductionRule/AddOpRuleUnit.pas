Unit AddOpRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function AddOpRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Function AddOpExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;

Implementation

Uses
  BinaryOpNode;

Function AddOpExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := True;
  New(PBinaryOpNode(Ast));
  TBinaryOpNode_Create(PBinaryOpNode(Ast));
  If TParser_Term(Parser, ePlus) Then
  Begin
    PBinaryOpNode(Ast).OpType := eAnd;
    Exit;
  End;
  If TParser_Term(Parser, eMinus) Then
  Begin
    PBinaryOpNode(Ast).OpType := eSubtract;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eOr) Then
  Begin
    PBinaryOpNode(Ast).OpType := eOr;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eXor) Then
  Begin
    PBinaryOpNode(Ast).OpType := eXor;
    Exit;
  End;
  TBinaryOpNode_Destroy(Ast);
  Dispose(PBinaryOpNode(Ast));
  Ast := nil;
  Parser.Error := 'Additive operator expected.';
  Result := False;
End;

Function AddOpRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := AddOpExpression1(Parser, Ast);
End;

End.
