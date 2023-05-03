{ Unit OptionRuleUnit; }
Unit OptRUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, ASTNode;

Function OptionRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function OptionRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  IdNode, GRMRNODE, TrmRNode, 
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

{ optionRule -> Id Equal Id Semi }
Function OptionRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mKey: PChar;
  mValue: PChar;
Label
  S1, S2;
Begin
  S1:
    If TParser_TermByGrammarTokenKind(Parser, eId) Then
    Begin
      mKey := strnew(TParser_GetCurrentToken(Parser)^.Value);
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  If TParser_TermByGrammarTokenKind(Parser, eEqual) Then
  Begin
    { NOP }
  End
  Else
  Begin
    FreeStr(mKey);
    Result := False;
    Exit;
  End;
  If TParser_TermByGrammarTokenKind(Parser, eId) Then
  Begin
    mValue := strnew(TParser_GetCurrentToken(Parser)^.Value);
  End
  Else
  Begin
    FreeStr(mKey);
    Result := False;
    Exit;
  End;
  If TParser_TermByGrammarTokenKind(Parser, eSemi) Then
  Begin
    If StrComp(mKey, 'caseInsensitive') = 0 Then
    Begin
      PGrammarNode(Ast)^.Options[COption_CaseInsensitive].BooleanValue :=
        (StrComp(mValue, 'true') = 0);
    End; { else if .... for other options in the future }

    FreeStr(mKey);
    FreeStr(mValue);
  End
  Else
  Begin
    FreeStr(mKey);
    FreeStr(mValue);
    Result := False;
    Exit;
  End;
  S2:
    Result := True;
End;

Function OptionRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := OptionRuleExpression1(Parser, Ast);
End;

End.
