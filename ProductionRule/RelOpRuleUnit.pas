Unit RelOpRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function RelOpRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function RelOpExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  BinaryOpNode;

Function RelOpExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  New(PBinaryOpNode(Ast));
  TBinaryOpNode_Create(PBinaryOpNode(Ast));
  If TParser_Term(Parser, TTokenKind.eEqual) Then
  Begin
    PBinaryOpNode(Ast).OpType := eEqual;
    Result := True;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eNotEqual) Then
  Begin
    PBinaryOpNode(Ast).OpType := eNotEqual;
    Result := True;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eLT) Then
  Begin
    PBinaryOpNode(Ast).OpType := eLT;
    Result := True;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eGT) Then
  Begin
    PBinaryOpNode(Ast).OpType := eGT;
    Result := True;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eLE) Then
  Begin
    PBinaryOpNode(Ast).OpType := eLE;
    Result := True;
    Exit;
  End;
  If TParser_Term(Parser, TTokenKind.eGE) Then
  Begin
    PBinaryOpNode(Ast).OpType := eGE;
    Result := True;
    Exit;
  End;
  TBinaryOpNode_Destroy(Ast);
  Dispose(PBinaryOpNode(Ast));
  Ast := nil;
  Parser.Error := 'Relational operator expected.';
  Result := False;
End;

Function RelOpRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := RelOpExpression1(Parser, Ast);
End;

End.
