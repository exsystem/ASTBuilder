Unit FactorRule;

{$MODE DELPHI}

Interface

Uses
  Parser, Lexer;

Function FactorRule(Parser: PParser): Boolean;
Function FactorExpression1(Parser: PParser): Boolean;


Implementation

Uses
  TermRule, TypeDef;

Function FactorRule(Parser: PParser): Boolean;
Begin
  Result := FactorExpression1(Parser);
End;

Function FactorExpression1(Parser: PParser): Boolean;
Var
  mTemp: TSize;
Begin
  Result := TermRule.TermRule(Parser);
  If Result = False Then
  Begin
    Exit;
  End;
  While Not TParser_MatchNextToken(Parser, TTokenKind.eEof) Do
  Begin
    mTemp := Parser.FCurrentToken;
    Result := ((TParser_MatchNextToken(Parser, TTokenKind.eMul) Or
      TParser_MatchNextToken(Parser, TTokenKind.eDiv)) And TermRule.TermRule(Parser));
    If Not Result Then
    Begin
      Parser.FCurrentToken := mTemp;
      Exit(True);
    End;
  End;
End;

End.
