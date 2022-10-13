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
  If TParser_Term(Parser, eAdd) Or TParser_Term(Parser, eSub) Or
    TParser_Term(Parser, TTokenKind.eOr) Or TParser_Term(Parser, TTokenKind.eXor) Then
  Begin
    Result := True;
    New(PBinaryOpNode(Ast));
    TBinaryOpNode_Create(PBinaryOpNode(Ast));
    If TParser_IsToken(Parser, eAdd) Then
    Begin
      PBinaryOpNode(Ast).OpType := ePlus;
    End
    Else
    If TParser_IsToken(Parser, eSub) Then
    Begin
      PBinaryOpNode(Ast).OpType := eMinus;
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
