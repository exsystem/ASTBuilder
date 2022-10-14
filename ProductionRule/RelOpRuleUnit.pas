Unit RelOpRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function RelOpRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Function RelOpExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;

Implementation

Uses
  BinaryOpNode;

Function RelOpExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := True;
  New(PBinaryOpNode(Ast));
  TBinaryOpNode_Create(PBinaryOpNode(Ast));
  If TParser_Term(Parser, TTokenKind.eEqual) Then
  Begin
    PBinaryOpNode(Ast).OpType := eEqual;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eNotEqual) Then
  Begin
    PBinaryOpNode(Ast).OpType := eNotEqual;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eLT) Then
  Begin
    PBinaryOpNode(Ast).OpType := eLT;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eGT) Then
  Begin
    PBinaryOpNode(Ast).OpType := eGT;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eLE) Then
  Begin
    PBinaryOpNode(Ast).OpType := eLE;
  End;
  If TParser_Term(Parser, TTokenKind.eGE) Then
  Begin
    PBinaryOpNode(Ast).OpType := eGE;
    Exit;
  End;
  TBinaryOpNode_Destroy(Ast);
  Dispose(PBinaryOpNode(Ast));
  Ast := nil;
  Parser.Error := 'Relational operator expected.';
  Result := False;
End;

Function RelOpRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := RelOpExpression1(Parser, Ast);
End;

End.
