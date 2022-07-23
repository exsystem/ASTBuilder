Unit TermRule;

{$MODE DELPHI}

Interface

Uses
  Parser, Lexer;

Function TermRule(Parser: PParser): Boolean;
Function TermExpression1(Parser: PParser): Boolean;
Function TermExpression2(Parser: PParser): Boolean;

Implementation

uses
  ExprRule;

Function TermExpression1(Parser: PParser): Boolean;
Begin
  Result := TParser_MatchNextToken(Parser, TTokenKind.eNum);
End;

Function TermRule(Parser: PParser): Boolean;
Begin
  Result := TermExpression1(Parser) Or TermExpression2(Parser);
End;

Function TermExpression2(Parser: PParser): Boolean;
Begin
  Result := (TParser_MatchNextToken(Parser, TTokenKind.eLParent) And
    ExprRule.ExprRule(Parser) And TParser_MatchNextToken(Parser, TTokenKind.eRParent));
End;

End.
