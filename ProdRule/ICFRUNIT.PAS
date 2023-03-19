{ Unit IndividualCharFactorRuleUnit; }
Unit ICFRUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, NFA;

Function IndividualCharFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function IndividualCharFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Function IndividualCharFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;

Function IndividualCharFactorRuleExpression3(Parser: PParser; Var Nfa: PNfa): Boolean;

Function IndividualCharFactorRuleExpression4(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TrmNode, GrpNode,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtils;

{ individualCharFactor -> Char DoubleDots Char }
Function IndividualCharFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mSavePointS1: TSize;
  mFrom, mTo: PChar;
  mCh: Char;
  mChStr: PChar;
Label
  S1, S2, S3, S4;
Begin
  S1:
    mSavePointS1 := Parser^.FCurrentToken;
  If TParser_TermByGrammarTokenKind(Parser, eChar) Then
  Begin
    mFrom := strnew(TParser_GetCurrentToken(Parser)^.Value);
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  S2:
    If TParser_TermByGrammarTokenKind(Parser, eDoubleDots) Then
    Begin
    End
    Else
    Begin
      FreeStr(mFrom);
      Parser^.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S3:
    If TParser_TermByGrammarTokenKind(Parser, eChar) Then
    Begin
      mTo := strnew(TParser_GetCurrentToken(Parser)^.Value);
    End
    Else
    Begin
      FreeStr(mFrom);
      Parser^.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S4:
    If mFrom[1] = '\' Then
    Begin
      mFrom[0] := EscapeChar(mFrom[2]);
    End
    Else
    Begin
      mFrom[0] := mFrom[1];
    End;
  If mTo[1] = '\' Then
  Begin
    mTo[0] := EscapeChar(mTo[2]);
  End
  Else
  Begin
    mTo[0] := mTo[1];
  End;
  TNfa_Create(Nfa);
  mChStr := CreateStr(1);
  mChStr[1] := #0;
  For mCh := mFrom[0] To mTo[0] Do
  Begin
    mChStr[0] := mCh;
    TNfa_AddEdge(Nfa, mChStr, 0, 1);
  End;
  FreeStr(mChStr);
  FreeStr(mFrom);
  FreeStr(mTo);
  TNfa_GetState(Nfa, 1)^.Acceptable := True;
  Result := True;
End;

{ individualCharFactor -> Char }
Function IndividualCharFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
Label
  S1, S2;
Var
  mCh: PChar;
  mValue: PChar;
Begin
  S1:
    If TParser_TermByGrammarTokenKind(Parser, eChar) Then
    Begin
      { NOP }
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    mValue := TParser_GetCurrentToken(Parser)^.Value;
  TNfa_Create(Nfa);
  mCh := CreateStr(1);
  If mValue[1] = '\' Then
  Begin
    mCh[0] := EscapeChar(mValue[2]);
  End
  Else
  Begin
    mCh[0] := mValue[1];
  End;
  mCh[1] := #0;
  TNfa_AddEdge(Nfa, mCh, 0, 1);
  FreeStr(mCh);
  TNfa_GetState(Nfa, 1)^.Acceptable := True;
  Result := True;
End;

{ TODO individualCharFactor -> CharSet ; [a-z\n\r] }
Function IndividualCharFactorRuleExpression3(Parser: PParser; Var Nfa: PNfa): Boolean;
Label
  S1;
Var
  mTerm: PChar;
  mChList: PChar;
  mSourceStart: PChar;
  mDestStart: PChar;
  mLength: TSize;
  mCurr: PChar;
  mRangeMode: Boolean;
  mCh: PChar;
Begin
  S1:
    If TParser_TermByGrammarTokenKind(Parser, eCharSet) Then
    Begin
      mTerm := TParser_GetCurrentToken(Parser)^.Value;
      mCurr := SubStr(mTerm, 1, StrLen(mTerm) - 2);
      mChList := CreateStr(StrLen(mCurr));
      mSourceStart := mCurr;
      mDestStart := mChList;
      mLength := 0;
      mCh := mCurr;
      While mCh^ <> #0 Do
      Begin
        If mCh^ = '\' Then
        Begin
          Move(mSourceStart^, mDestStart^, mLength * SizeOf(Char));
          Inc(mDestStart, mLength);
          Inc(mCh);
          mCh^ := EscapeChar(mCh^);
          mSourceStart := mCh;
          mLength := 0;
        End;
        Inc(mLength);
        Inc(mCh);
      End;
      Move(mSourceStart^, mDestStart^, mLength * SizeOf(Char));
      Inc(mDestStart, mLength);
      mDestStart^ := #0;
      FreeStr(mCurr);

      mSourceStart := mChList;
      mCurr := mChList;
      mRangeMode := False;
      TNfa_Create(Nfa);
      mCh := CreateStr(1);
      mCh[1] := #0;
      Repeat
        If mCurr^ = '-' Then
        Begin
          mRangeMode := True;
        End
        Else
        Begin
          If mRangeMode Then
          Begin
            mCh[0] := mSourceStart^;
            Inc(mCh[0]);
            While mCh[0] <> mCurr^ Do
            Begin
              TNfa_AddEdge(Nfa, mCh, 0, 1);
              Inc(mCh[0]);
            End;
            TNfa_AddEdge(Nfa, mCh, 0, 1);
            mRangeMode := False;
          End
          Else
          Begin
            mCh[0] := mCurr^;
            TNfa_AddEdge(Nfa, mCh, 0, 1);
            mSourceStart := mCurr;
          End;
        End;

        Inc(mCurr);
      Until mCurr = mDestStart;

      FreeStr(mCh);
      mDestStart^ := '.';
      FreeStr(mChList);
      Result := True;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
End;

Function IndividualCharFactorRuleExpression4(Parser: PParser; Var Nfa: PNfa): Boolean;
Label
  S1, S2;
Begin
  S1:
    If TParser_TermByGrammarTokenKind(Parser, eDot) Then
    Begin
      { NOP }
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    TNfa_Create(Nfa);
  TNfa_AnyChar(Nfa, 0, 1);
  Result := True;
End;

Function IndividualCharFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := IndividualCharFactorRuleExpression1(Parser, Nfa) Or
    IndividualCharFactorRuleExpression2(Parser, Nfa) Or
    IndividualCharFactorRuleExpression3(Parser, Nfa) Or
    IndividualCharFactorRuleExpression4(Parser, Nfa);
End;

End.
