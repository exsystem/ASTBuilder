Unit TermRule;

{$MODE DELPHI}

Interface

Uses
  Parser, Lexer;

Function TermRule(Parser: PParser): Boolean;
Function TermExpression1(Parser: PParser): Boolean;
Function TermExpression2(Parser: PParser): Boolean;

Implementation

Uses
  ExprRule;

Function TermExpression1(Parser: PParser): Boolean;
Begin
  Result := TParser_Term(Parser, TTokenKind.eNum);
End;

Function TermRule(Parser: PParser): Boolean;
Begin
  Exit(TParser_Prod(Parser, [@TermExpression1, @TermExpression2]));
  // Result := TermExpression1(Parser) Or TermExpression2(Parser);
End;

Function TermExpression2(Parser: PParser): Boolean;
Begin
  Result := (TParser_Term(Parser, TTokenKind.eLParent) And
    ExprRule.ExprRule(Parser) And TParser_Term(Parser, TTokenKind.eRParent));
End;

End.
