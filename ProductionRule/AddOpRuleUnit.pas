Unit AddOpRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function AddOpRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function AddOpExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  BinaryOpNode;

Function AddOpExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  If TParser_Term(Parser, ePlus) Or TParser_Term(Parser, eMinus) Or
    TParser_Term(Parser, TTokenKind.eOr) Or TParser_Term(Parser, TTokenKind.eXor) Then
  Begin
    Result := True;
    New(PBinaryOpNode(Ast));
    TBinaryOpNode_Create(PBinaryOpNode(Ast));
    If TParser_IsToken(Parser, ePlus) Then
    Begin
      PBinaryOpNode(Ast).OpType := eAnd;
    End
    Else
    If TParser_IsToken(Parser, eMinus) Then
    Begin
      PBinaryOpNode(Ast).OpType := eSubtract;
    End
    Else
    If TParser_IsToken(Parser, TTokenKind.eOr) Then
    Begin
      PBinaryOpNode(Ast).OpType := eOr;
    End
    Else
    If TParser_IsToken(Parser, TTokenKind.eXor) Then
    Begin
      PBinaryOpNode(Ast).OpType := eXor;
    End;
  End
  Else
  Begin
    Result := False;
  End;
  If Not Result Then
  Begin
    Parser.Error := 'Add binary operand expected.';
    Exit;
  End;
End;

Function AddOpRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := AddOpExpression1(Parser, Ast);
End;

End.
