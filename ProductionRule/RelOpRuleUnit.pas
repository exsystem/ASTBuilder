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
  If TParser_Term(Parser, TTokenKind.eEqual) Or TParser_Term(Parser,
    TTokenKind.eNotEqual) Or TParser_Term(Parser, TTokenKind.eLT) Or
    TParser_Term(Parser, TTokenKind.eGT) Or TParser_Term(Parser, TTokenKind.eLE) Or
    TParser_Term(Parser, TTokenKind.eGT) Then
  Begin
    Result := True;
    New(PBinaryOpNode(Ast));
    TBinaryOpNode_Create(PBinaryOpNode(Ast));
    If TParser_IsToken(Parser, TTokenKind.eEqual) Then
    Begin
      PBinaryOpNode(Ast).OpType := eEqual;
    End
    Else
    If TParser_IsToken(Parser, TTokenKind.eNotEqual) Then
    Begin
      PBinaryOpNode(Ast).OpType := eNotEqual;
    End
    Else
    If TParser_IsToken(Parser, TTokenKind.eLT) Then
    Begin
      PBinaryOpNode(Ast).OpType := eLT;
    End
    Else
    If TParser_IsToken(Parser, TTokenKind.eGT) Then
    Begin
      PBinaryOpNode(Ast).OpType := eGT;
    End
    Else
    If TParser_IsToken(Parser, TTokenKind.eLE) Then
    Begin
      PBinaryOpNode(Ast).OpType := eLE;
    End
    Else
    If TParser_IsToken(Parser, TTokenKind.eGE) Then
    Begin
      PBinaryOpNode(Ast).OpType := eGE;
    End;
  End
  Else
  Begin
    Result := False;
  End;
  If Not Result Then
  Begin
    Parser.Error := 'Relational binary operand expected.';
    Exit;
  End;
End;

Function RelOpRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := RelOpExpression1(Parser, Ast);
End;

End.
