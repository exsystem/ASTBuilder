{ Unit TermFactorRuleUnit; }
Unit TFRUnit;

{$I define.inc}

Interface

Uses
  Parser, NFA;

Function TermFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function TermFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Function TermFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TrmNode, GrpNode, TERUnit,
  SFRUnit, GLEXER, GPARSER;

{ termFactor -> LParen termExpr RParen ( QuestionMark ( QuestionMark ? ) |
                Plus ( QuestionMark ? ) | Asterisk ( QuestionMark ? ) ) ? }
Function TermFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mSavePointS4: TSize;
  mNfa: PNfa;
Label
  S1, S2, S3, S4, S5;
Begin
  S1:
    If TGrammarParser_Term(Parser, eLParen) Then
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
    If TGrammarParser_Term(Parser, eRParen) Then
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
  If TGrammarParser_Term(Parser, eQuestionMark) Then
  Begin
    TNfa_Optional(Nfa, TGrammarParser_Term(Parser, eQuestionMark));
  End
  Else If TGrammarParser_Term(Parser, ePlus) Then
  Begin
    TNfa_OneOrMore(Nfa, TGrammarParser_Term(Parser, eQuestionMark));
  End
  Else If TGrammarParser_Term(Parser, eAsterisk) Then
  Begin
    TNfa_Multiple(Nfa, TGrammarParser_Term(Parser, eQuestionMark));
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

{ termFactor -> stringFactor ( QuestionMark ( QuestionMark ? ) | Plus ( QuestionMark ? ) | Asterisk ( QuestionMark ? ) ) ? }
Function TermFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
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
  If TGrammarParser_Term(Parser, eQuestionMark) Then
  Begin
    TNfa_Optional(Nfa, Not TGrammarParser_Term(Parser, eQuestionMark));
  End
  Else If TGrammarParser_Term(Parser, ePlus) Then
  Begin
    TNfa_OneOrMore(Nfa, Not TGrammarParser_Term(Parser, eQuestionMark));
  End
  Else If TGrammarParser_Term(Parser, eAsterisk) Then
  Begin
    TNfa_Multiple(Nfa, Not TGrammarParser_Term(Parser, eQuestionMark));
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


Function TermFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := TermFactorRuleExpression1(Parser, Nfa) Or
    TermFactorRuleExpression2(Parser, Nfa);
End;

End.
