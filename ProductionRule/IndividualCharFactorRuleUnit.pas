Unit IndividualCharFactorRuleUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, NFA;

Function IndividualCharFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function IndividualCharFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Function IndividualCharFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TermNode, GroupNode,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StringUtils;

// individualCharFactor -> Char DoubleDots Char
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
    mSavePointS1 := Parser.FCurrentToken;
  If TParser_Term(Parser, eChar) Then
  Begin
    mFrom := strnew(TParser_GetCurrentToken(Parser).Value);
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  S2:
    If TParser_Term(Parser, eDoubleDots) Then
    Begin
    End
    Else
    Begin
      FreeStr(mFrom);
      Parser.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S3:
    If TParser_Term(Parser, eChar) Then
    Begin
      mTo := strnew(TParser_GetCurrentToken(Parser).Value);
    End
    Else
    Begin
      FreeStr(mFrom);
      Parser.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S4:
    If mFrom[1] = '\' Then
      // TODO extract a util function. and add more chars allowing escaping.
    Begin
      Case mFrom[2] Of
        'n': mFrom[0] := #13;
        'r': mFrom[0] := #10;
        't': mFrom[0] := #20;
        Else
          mFrom[0] := mFrom[2];
      End;
    End
    Else
    Begin
      mFrom[0] := mFrom[1];
    End;
  If mTo[1] = '\' Then
  Begin
    Case mTo[2] Of
      'n': mTo[0] := #13;
      'r': mTo[0] := #10;
      't': mTo[0] := #20;
      Else
        mTo[0] := mTo[2];
    End;
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
  TNfa_GetState(Nfa, 1).Acceptable := True;
  Result := True;
End;

// individualCharFactor -> Char 
Function IndividualCharFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
Label
  S1, S2;
Var
  mCh: PChar;
Begin
  S1:
    If TParser_Term(Parser, eChar) Then
    Begin
      // NOP
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    TNfa_Create(Nfa);
  mCh := CreateStr(1);
  mCh[0] := TParser_GetCurrentToken(Parser).Value[1];
  mCh[1] := #0;
  TNfa_AddEdge(Nfa, mCh, 0, 1);
  FreeStr(mCh);
  // TODO: ['a'] or [a]; and what about ['\n']?
  TNfa_GetState(Nfa, 1).Acceptable := True;
  Result := True;
End;

// TODO individualCharFactor -> CharSet ; [a-z\n\r]

Function IndividualCharFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := IndividualCharFactorRuleExpression1(Parser, Nfa) Or
    IndividualCharFactorRuleExpression2(Parser, Nfa);
End;

End.
