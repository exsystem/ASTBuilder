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
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil, GLEXER, GPARSER;

{ individualCharFactor -> TChar DoubleDots TChar }
Function IndividualCharFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mSavePointS1: TSize;
  mFrom, mTo: PTChar;
  mCh: Byte;
  mChStr: PTChar;
Label
  S1, S2, S3, S4;
Begin
  S1:
    mSavePointS1 := Parser^.FCurrentToken;
  If TGrammarParser_Term(Parser, eChar) Then
  Begin
    mFrom := TCharStrNew(TParser_GetCurrentToken(Parser)^.Value);
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  S2:
    If TGrammarParser_Term(Parser, eDoubleDots) Then
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
    If TGrammarParser_Term(Parser, eChar) Then
    Begin
      mTo := TCharStrNew(TParser_GetCurrentToken(Parser)^.Value);
    End
    Else
    Begin
      FreeStr(mFrom);
      Parser^.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S4:
    If PByte(mFrom)[1] = Ord('\') Then
    Begin
      PByte(mFrom)[0] := EscapeChar(PByte(mFrom)[2]);
    End
    Else
    Begin
      PByte(mFrom)[0] := PByte(mFrom)[1];
    End;
  If PByte(mTo)[1] = Ord('\') Then
  Begin
    PByte(mTo)[0] := EscapeChar(PByte(mTo)[2]);
  End
  Else
  Begin
    PByte(mTo)[0] := PByte(mTo)[1];
  End;
  TNfa_Create(Nfa);
  mChStr := CreateStr(1);
  PByte(mChStr)[1] := 0;
  For mCh := PByte(mFrom)^ To PByte(mTo)^ Do
  Begin
    PByte(mChStr)^ := mCh;
    TNfa_AddEdge(Nfa, mChStr, 0, 1);
  End;
  FreeStr(mChStr);
  FreeStr(mFrom);
  FreeStr(mTo);
  TNfa_GetState(Nfa, 1)^.Acceptable := True;
  Result := True;
End;

{ individualCharFactor -> TChar }
Function IndividualCharFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
Label
  S1, S2;
Var
  mCh: PTChar;
  mValue: PTChar;
Begin
  S1:
    If TGrammarParser_Term(Parser, eChar) Then
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
  If PByte(mValue)[1] = Ord('\') Then
  Begin
    PByte(mCh)[0] := EscapeChar(PByte(mValue)[2]);
  End
  Else
  Begin
    PByte(mCh)[0] := PByte(mValue)[1];
  End;
  PByte(mCh)[1] := 0;
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
  mTerm: PTChar;
  mChList: PTChar;
  mSourceStart: PTChar;
  mDestStart: PTChar;
  mLength: TSize;
  mCurr: PTChar;
  mRangeMode: Boolean;
  mCh: PTChar;
Begin
  S1:
    If TGrammarParser_Term(Parser, eCharSet) Then
    Begin
      mTerm := TParser_GetCurrentToken(Parser)^.Value;
      mCurr := SubStr(mTerm, 1, TCharStrLen(mTerm) - 2);
      mChList := CreateStr(TCharStrLen(mCurr));
      mSourceStart := mCurr;
      mDestStart := mChList;
      mLength := 0;
      mCh := mCurr;
      While PByte(mCh)^ <> 0 Do
      Begin
        If PByte(mCh)^ = Ord('\') Then
        Begin
          Move(mSourceStart^, mDestStart^, mLength * SizeOf(TChar));
          Inc(mDestStart, mLength);
          Inc(mCh);
          PByte(mCh)^ := EscapeChar(PByte(mCh)^);
          mSourceStart := mCh;
          mLength := 0;
        End;
        Inc(mLength);
        Inc(mCh);
      End;
      Move(mSourceStart^, mDestStart^, mLength * SizeOf(TChar));
      Inc(mDestStart, mLength);
      PByte(mDestStart)^ := 0;
      FreeStr(mCurr);

      mSourceStart := mChList;
      mCurr := mChList;
      mRangeMode := False;
      TNfa_Create(Nfa);
      mCh := CreateStr(1);
      PByte(mCh)[1] := 0;
      Repeat
        If PByte(mCurr)^ = Ord('-') Then
        Begin
          mRangeMode := True;
        End
        Else
        Begin
          If mRangeMode Then
          Begin
            PByte(mCh)^ := PByte(mSourceStart)^;
            Inc(PByte(mCh)^);
            While PByte(mCh)^ <> PByte(mCurr)^ Do
            Begin
              TNfa_AddEdge(Nfa, mCh, 0, 1);
              Inc(PByte(mCh)^);
            End;
            TNfa_AddEdge(Nfa, mCh, 0, 1);
            mRangeMode := False;
          End
          Else
          Begin
            PByte(mCh)^ := PByte(mCurr)^;
            TNfa_AddEdge(Nfa, mCh, 0, 1);
            mSourceStart := mCurr;
          End;
        End;

        Inc(mCurr);
      Until mCurr = mDestStart;

      FreeStr(mCh);
      PByte(mDestStart)^ := Ord('.');
      FreeStr(mChList);
      TNfa_GetState(Nfa, 1)^.Acceptable := True;
      Result := True;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
End;

{ individualCharFactor -> Dot ; }
Function IndividualCharFactorRuleExpression4(Parser: PParser; Var Nfa: PNfa): Boolean;
Label
  S1, S2;
Begin
  S1:
    If TGrammarParser_Term(Parser, eDot) Then
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
  TNfa_GetState(Nfa, 1)^.Acceptable := True;
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
