{ Unit TermFactorRuleUnit; }
Unit TFRUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, NFA;

Function TermFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function TermFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Function TermFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TrmNode, GrpNode, TERUnit,
  SFRUnit;

{ termFactor -> stringFactor ( QuestionMark | Plus | Asterisk ) ? }
Function TermFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mSavePointS2: TSize;
Label
  S1, S2, S3;
Begin
  S1:
    If StringFactorRule(Parser, Nfa) Then
    Begin
      { NOP }
    End
    Else
    Begin
      Result := False; { S1 is a Non-Accepted State Node in DFA. }
      Exit;
    End;
  S2:
    mSavePointS2 := Parser^.FCurrentToken;
  If TParser_TermByGrammarTokenKind(Parser, eQuestionMark) Then
  Begin
    TNfa_Optional(Nfa);
  End
  Else If TParser_TermByGrammarTokenKind(Parser, ePlus) Then
  Begin
    TNfa_OneOrMore(Nfa);
  End
  Else If TParser_TermByGrammarTokenKind(Parser, eAsterisk) Then
  Begin
    TNfa_Multiple(Nfa);
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS2;
    Result := True; { S2 is a accpeted state node in DFA. }
    Exit;
  End;
  S3:
    Result := True;
End;

{ termFactor -> LParen termExpr RParen ( QuestionMark | Plus | Asterisk ) ? }
Function TermFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mSavePointS4: TSize;
  mNfa: PNfa;
Label
  S1, S2, S3, S4, S5;
Begin
  S1:
    If TParser_TermByGrammarTokenKind(Parser, eLParen) Then
    Begin
      { NOP }
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    If TermExprRule(Parser, mNfa) Then
    Begin
      { NOP }
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S3:
    If TParser_TermByGrammarTokenKind(Parser, eRParen) Then
    Begin
      { NOP }
    End
    Else
    Begin
      TNfa_Destroy(mNfa);
      Result := False;
      Exit;
    End;
  S4:
    mSavePointS4 := Parser^.FCurrentToken;
  Nfa := mNfa;
  If TParser_TermByGrammarTokenKind(Parser, eQuestionMark) Then
  Begin
    TNfa_Optional(Nfa);
  End
  Else If TParser_TermByGrammarTokenKind(Parser, ePlus) Then
  Begin
    TNfa_OneOrMore(Nfa);
  End
  Else If TParser_TermByGrammarTokenKind(Parser, eAsterisk) Then
  Begin
    TNfa_Multiple(Nfa);
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS4;
    Result := True;
    Exit;
  End;
  S5:
    Result := True;
End;

Function TermFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := TermFactorRuleExpression1(Parser, Nfa) Or
    TermFactorRuleExpression2(Parser, Nfa);
End;

End.
