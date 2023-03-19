{ Unit StringFactorRuleUnit; }
Unit SFRUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, NFA;

Function StringFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function StringFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Function StringFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TrmNode, GrpNode, ChFRUnit,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtils;

{ stringFactor -> charFactor }
Function StringFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := CharFactorRule(Parser, Nfa);
End;

{ stringFactor -> string }
Function StringFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mToken: PToken;
  I, J: TSize;
  mCh: PChar;
  mEscaping: Boolean;
Label
  S1, S2;
Begin
  S1:
    If TParser_TermByGrammarTokenKind(Parser, eString) Then
    Begin
      TNfa_Create(Nfa);
      mToken := TParser_GetCurrentToken(Parser);
      mCh := CreateStr(1);
      mCh[1] := #0;

      mEscaping := False;
      I := 1;
      J:=0;
      While I < strlen(mToken^.Value) - 1 Do
      Begin
        If mEscaping Then
        Begin
          mEscaping := False;
          mCh[0] := EscapeChar(mToken^.Value[I]);
        End
        Else
        If mToken^.Value[I] = '\' Then
        Begin
          mEscaping := True;
          Inc(I);
          Continue;
        End
        Else
        Begin
          mCh[0] := EscapeChar(mToken^.Value[I]);
        End;
        TNfa_AddEdge(Nfa, mCh, J, J + 1);
        Inc(J);
        Inc(I);
      End;
      FreeStr(mCh);
      TNfa_GetState(Nfa, Nfa^.States^.Size - 1)^.Acceptable := True;
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
