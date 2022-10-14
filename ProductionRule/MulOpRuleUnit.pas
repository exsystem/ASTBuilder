Unit MulOpRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function MulOpRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Function MulOpExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;

Implementation

Uses
  BinaryOpNode;

Function MulOpExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := True;
  New(PBinaryOpNode(Ast));
  TBinaryOpNode_Create(PBinaryOpNode(Ast));
  If TParser_Term(Parser, eMul) Then
  Begin
    PBinaryOpNode(Ast).OpType := eMultiply;
    Exit;
  End;
  If TParser_Term(Parser, eSlash) Then
  Begin
    PBinaryOpNode(Ast).OpType := eRealDivide;
    Exit;
  End;
  If TParser_Term(Parser, eDiv) Then
  Begin
    PBinaryOpNode(Ast).OpType := eIntDivide;
    Exit;
  End;
  If TParser_Term(Parser, eMod) Then
  Begin
    PBinaryOpNode(Ast).OpType := eModulo;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eAnd) Then
  Begin
    PBinaryOpNode(Ast).OpType := eAnd;
    Exit;
  End;
  If TParser_Term(Parser, eShl) Then
  Begin
    PBinaryOpNode(Ast).OpType := eShiftLeft;
    Exit;
  End;
  If TParser_Term(Parser, eShr) Then
  Begin
    PBinaryOpNode(Ast).OpType := eShiftRight;
    Exit;
  End;
  TBinaryOpNode_Destroy(Ast);
  Dispose(PBinaryOpNode(Ast));
  Ast := nil;
  Parser.Error := 'Multiplicative operator expected.';
  Result := False;
End;

Function MulOpRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := MulOpExpression1(Parser, Ast);
End;

End.
