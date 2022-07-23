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
  Result := ExprExpression1(Parser);
End;

// Expr -> Factor ( opExpr Factor )*
Function ExprExpression1(Parser: PParser): Boolean;
Var
  mTemp: TSize;
Begin
  Result := FactorRule.FactorRule(Parser);
  If Result = False Then
  Begin
    Exit;
  End;
  // the loop: ( opExpr Factor ) * 
  While Not TParser_MatchNextToken(Parser, TTokenKind.eEof) Do
  Begin
    mTemp := Parser.FCurrentToken; // Mark the position as a new term of 'opExpr Factor' begins, for fallback purpose if parsing fails.
    Result := ((TParser_MatchNextToken(Parser, TTokenKind.eAdd) Or
      (TParser_MatchNextToken(Parser, TTokenKind.eSub))) And
      FactorRule.FactorRule(Parser));
    If Not Result Then
    Begin
      Parser.FCurrentToken := mTemp; // Fallback to the marked position.
      Exit(True);
    End;
  End;
End;

End.
