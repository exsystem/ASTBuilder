Unit SignFactorRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, ASTNode;

Function SignFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function SignFactorExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TermRuleUnit, SignOpRuleUnit, UnaryOpNode;

// SignFactor -> ( SignOp )? Term
Function SignFactorExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSignNode: PAstNode;
Begin
  mSignNode := nil;
  SignOpRule(Parser, mSignNode);
  If Not TermRule(Parser, Ast) Then
  Begin
    Parser.Error := 'Number expected.';
    If mSignNode <> nil Then
    Begin
      TUnaryOpNode_Destroy(PAstNode(mSignNode));
      Dispose(mSignNode);
    End;
    Result := False;
    Exit;
  End;
  If mSignNode <> nil Then
  Begin
    PUnaryOpNode(mSignNode).Value := Ast;
    Ast := mSignNode;
  End;
  Result := True;
End;

Function SignFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := SignFactorExpression1(Parser, Ast);
End;

End.
