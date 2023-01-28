Unit StringFactorRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, NFA;

Function StringFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function StringFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Function StringFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;

Function StringFactorRuleExpression3(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TermNode, GroupNode;

// stringFactor -> char DoubleDots char
Function StringFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mSavePointS1: TSize;
  mFrom, mTo: String;
  mCh: Char;
Label
  S1, S2, S3, S4;
Begin
  S1:
    mSavePointS1 := Parser.FCurrentToken;
  If TParser_Term(Parser, eChar) Then
  Begin
    mFrom := TParser_GetCurrentToken(Parser).Value;
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
      Parser.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S3:
    If TParser_Term(Parser, eChar) Then
    Begin
      mTo := TParser_GetCurrentToken(Parser).Value;
    End
    Else
    Begin
      Parser.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S4:
    If mFrom[2] = '\' Then
      // TODO extract a util function. and add more chars allowing escaping.
    Begin
      Case mFrom[3] Of
        'n': mFrom := #13;
        'r': mFrom := #10;
        't': mFrom := #20;
        Else
          mFrom := mFrom[3];
      End;
    End
    Else
    Begin
      mFrom := mFrom[2];
    End;
  If mTo[2] = '\' Then
  Begin
    Case mTo[3] Of
      'n': mTo := #13;
      'r': mTo := #10;
      't': mTo := #20;
      Else
        mTo := mTo[3];
    End;
  End
  Else
  Begin
    mTo := mTo[2];
  End;
  TNfa_Create(Nfa);
  For mCh := mFrom[1] To mTo[1] Do
  Begin
    TNfa_AddEdge(Nfa, mCh, 0, 1);
  End;
  TNfa_GetState(Nfa, 1).Acceptable := True;
  Result := True;
End;

// stringFactor -> char
Function StringFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
Label
  S1, S2;
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
  TNfa_AddEdge(Nfa, TParser_GetCurrentToken(Parser).Value[2], 0, 1);
  // TODO: ['a'] or [a]; and what about ['\n']?
  TNfa_GetState(Nfa, 1).Acceptable := True;
  Result := True;
End;

// stringFactor -> string
Function StringFactorRuleExpression3(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mToken: PToken;
  I: TSize;
Label
  S1, S2;
Begin
  S1:
    If TParser_Term(Parser, eString) Then
    Begin
      TNfa_Create(Nfa);
      mToken := TParser_GetCurrentToken(Parser);
      For I := Low(mToken.Value) + 1 To High(mToken.Value) - 1 Do
      Begin
        TNfa_AddEdge(Nfa, mToken.Value[I], I - (Low(mToken.Value) + 1),
        I - (Low(mToken.Value) + 1) + 1);
      End;
      TNfa_GetState(Nfa, Nfa.States.Size - 1).Acceptable := True;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    Result := True;
End;

Function StringFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := StringFactorRuleExpression1(Parser, Nfa) Or
    StringFactorRuleExpression2(Parser, Nfa) Or StringFactorRuleExpression3(Parser, Nfa);
End;

End.
