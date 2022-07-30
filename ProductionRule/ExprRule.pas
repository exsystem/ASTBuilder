Unit ExprRule;

{$MODE DELPHI}

Interface

Uses
  Parser, Lexer;

Function ExprRule(Parser: PParser): Boolean;
Function ExprExpression1(Parser: PParser): Boolean;

Implementation

Uses
  FactorRule, TypeDef;

Function ExprRule(Parser: PParser): Boolean;
Begin
  Exit(TParser_Prod(Parser, [@ExprExpression1]));
  // Result := ExprExpression1(Parser);
End;

// Expr -> Factor ( opExpr Factor )*
Function ExprExpression1(Parser: PParser): Boolean;
Var
  mSavePoint: TSize;
Begin
  Result := FactorRule.FactorRule(Parser);
  If Result = False Then
  Begin
    Exit;
  End;
  // the loop: ( opExpr Factor )* 
  While Not TParser_Term(Parser, TTokenKind.eEof) Do
  Begin
    mSavePoint := Parser.FCurrentToken;
    // Mark the position as a new term of 'opExpr Factor' begins, for fallback purpose if parsing fails.
    Result := ((TParser_Term(Parser, TTokenKind.eAdd) Or
      (TParser_Term(Parser, TTokenKind.eSub))) And FactorRule.FactorRule(Parser));
    If Not Result Then
    Begin
      Parser.FCurrentToken := mSavePoint; // Fallback to the marked position.
      Exit(True);
    End;
  End;
End;

End.
