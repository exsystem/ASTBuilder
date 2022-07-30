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
  Exit(TParser_Prod(Parser, [@FactorExpression1]));
  // Result := FactorExpression1(Parser);
End;

Function FactorExpression1(Parser: PParser): Boolean;
Var
  mSavePoint: TSize;
Begin
  Result := TermRule.TermRule(Parser);
  If Result = False Then
  Begin
    Exit;
  End;
  While Not TParser_Term(Parser, TTokenKind.eEof) Do
  Begin
    mSavePoint := Parser.FCurrentToken;
    Result := ((TParser_Term(Parser, TTokenKind.eMul) Or
      TParser_Term(Parser, TTokenKind.eDiv)) And TermRule.TermRule(Parser));
    If Not Result Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      Exit(True);
    End;
  End;
End;

End.
