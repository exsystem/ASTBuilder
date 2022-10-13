Unit MulOpRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function MulOpRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function MulOpExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  BinaryOpNode;

Function MulOpExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  If TParser_Term(Parser, eMul) Or TParser_Term(Parser, eSlash) Or
    TParser_Term(Parser, eDiv) Or TParser_Term(Parser, eMod) Or
    TParser_Term(Parser, TTokenKind.eAnd) Or TParser_Term(Parser, eShl) Or
    TParser_Term(Parser, eShr) Then
  Begin
    Result := True;
    New(PBinaryOpNode(Ast));
    TBinaryOpNode_Create(PBinaryOpNode(Ast));
    If TParser_IsToken(Parser, eMul) Then
    Begin
      PBinaryOpNode(Ast).OpType := eMultiply;
    End
    Else
    If TParser_IsToken(Parser, eSlash) Then
    Begin
      PBinaryOpNode(Ast).OpType := eRealDivide;
    End
    Else
    If TParser_IsToken(Parser, eDiv) Then
    Begin
      PBinaryOpNode(Ast).OpType := eIntDivide;
    End
    Else
    If TParser_IsToken(Parser, eMod) Then
    Begin
      PBinaryOpNode(Ast).OpType := eModulo;
    End
    Else
    If TParser_IsToken(Parser, TTokenKind.eAnd) Then
    Begin
      PBinaryOpNode(Ast).OpType := eAnd;
    End
    Else
    If TParser_IsToken(Parser, eShl) Then
    Begin
      PBinaryOpNode(Ast).OpType := eShiftLeft;
    End
    Else
    If TParser_IsToken(Parser, eShr) Then
    Begin
      PBinaryOpNode(Ast).OpType := eShiftRight;
    End;
  End
  Else
  Begin
    Result := False;
  End;
  If Not Result Then
  Begin
    Parser.Error := 'Mul binary operand expected.';
    Exit;
  End;
End;

Function MulOpRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := MulOpExpression1(Parser, Ast);
End;

End.
