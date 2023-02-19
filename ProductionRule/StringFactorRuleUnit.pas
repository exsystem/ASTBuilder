Unit StringFactorRuleUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, NFA;

Function StringFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function StringFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Function StringFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TermNode, GroupNode, CharFactorRuleUnit,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StringUtils;

// stringFactor -> charFactor 
Function StringFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := CharFactorRule(Parser, Nfa);
End;

// stringFactor -> string
Function StringFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mToken: PToken;
  I: TSize;
  mCh: PChar;
Label
  S1, S2;
Begin
  S1:
    If TParser_Term(Parser, eString) Then
    Begin
      TNfa_Create(Nfa);
      mToken := TParser_GetCurrentToken(Parser);
      mCh := CreateStr(1);
      mCh[1] := #0;
      For I := 1 To strlen(mToken.Value) - 2 Do
      Begin
        mCh[0] := mToken.Value[I];
        TNfa_AddEdge(Nfa, mCh, I - 1, I);
      End;
      FreeStr(mCh);
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
    StringFactorRuleExpression2(Parser, Nfa);
End;

End.
