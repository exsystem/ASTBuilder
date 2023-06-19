{ Unit CharFactorRuleUnit; }
Unit ChFRUnit;

{$I define.inc}

Interface

Uses
  Parser, NFA;

Function CharFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function CharFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Function CharFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TrmNode, GrpNode, ICFRUnit, GLEXER, GPARSER;

{ charFactor -> Tilde? LParen individualCharFactor ( Or individualCharFactor )* RParen }
Function CharFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mSavePointS2, mSavePointS4: TSize;
  mFactorNode: PNfa;
  mNfa: PNfa;
  mNot: Boolean;
Label
  S1, S2, S3, S4, S5;
Begin
  mNfa := nil;

  S1:
    mNot := TGrammarParser_Term(Parser, eTilde);
  S2:
    mSavePointS2 := Parser^.FCurrentToken;
  If TGrammarParser_Term(Parser, eLParen) Then
  Begin
    { NOP }
  End
  Else
  Begin
    Result := False;
    Exit;
  End;

  S3:
    If IndividualCharFactorRule(Parser, mFactorNode) Then
    Begin
      mNfa := mFactorNode;
    End
    Else
    Begin
      Parser^.FCurrentToken := mSavePointS2;
      Result := False;
      Exit;
    End;
  S4:
    mSavePointS4 := Parser^.FCurrentToken;
  If TGrammarParser_Term(Parser, eOr) Then
  Begin
    { NOP }
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS4;
    Goto S5;
  End;
  If IndividualCharFactorRule(Parser, mFactorNode) Then
  Begin
    TNfa_MergeChars(mNfa, mFactorNode);
    Goto S4;
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS4;
    Goto S5;
  End;

  S5:
    If TGrammarParser_Term(Parser, eRParen) Then
    Begin
      If mNot Then
      Begin
        TNfa_Not(mNfa);
      End;
      Nfa := mNfa;
      Result := True;
      Exit;
    End
    Else
    Begin
      If mNfa <> nil Then
      Begin
        TNfa_Destroy(mNfa);
      End;
      Result := False;
      Exit;
    End;
End;

{ charFactor -> Tilde? individualCharFactor }
Function CharFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mNot: Boolean;
Label
  S1, S2, S3;
Begin
  S1:
    mNot := TGrammarParser_Term(Parser, eTilde);
  S2:
    If IndividualCharFactorRule(Parser, Nfa) Then
    Begin
      If mNot Then
      Begin
        TNfa_Not(Nfa);
      End;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S3:
    Result := True;
End;

Function CharFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := CharFactorRuleExpression1(Parser, Nfa) Or
    CharFactorRuleExpression2(Parser, Nfa);
End;

End.
