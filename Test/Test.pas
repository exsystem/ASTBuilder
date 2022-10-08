Unit Test;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Procedure Test1();

Implementation

Uses {$IFNDEF FPC}
  {$IFDEF VER150}
  TypInfo
  {$ELSE}
  System.Rtti
  {$ENDIF}
  , {$ENDIF}
  SysUtils,
  Lexer,
  Parser,
  ExprRuleUnit,
  AddRule,
  DivRule,
  EofRule,
  LParentRule,
  MulRule,
  NumRule,
  RParentRule,
  SubRule;

Procedure Test1();
Var
  mSource: String;
  mLexer: PLexer;
  mParser: PParser;
  mKind: String;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}

Label
  TestLexer, TestParser;

Begin
  Goto TestParser;

  TestLexer:
    While True Do
    Begin
      Readln(mSource);
      If mSource = '' Then
      Begin
        Goto TestParser;
      End;
      mLexer := TLexer_Create(mSource);
      TLexer_AddRule(mLexer, EofRule.Compose());
      TLexer_AddRule(mLexer, AddRule.Compose());
      TLexer_AddRule(mLexer, SubRule.Compose());
      TLexer_AddRule(mLexer, MulRule.Compose());
      TLexer_AddRule(mLexer, DivRule.Compose());
      TLexer_AddRule(mLexer, LParentRule.Compose());
      TLexer_AddRule(mLexer, RParentRule.Compose());
      TLexer_AddRule(mLexer, NumRule.Compose());
      Repeat
        If TLexer_GetNextToken(mLexer) Then
        Begin
        {$IFDEF FPC}
        WriteStr(mKind, mLexer.CurrentToken.Kind);
        {$ELSE}
          {$IFDEF VER150}
          tInfo := TypeInfo(TTokenKind);
          mKind := GetEnumName(tInfo, Ord(mLexer.CurrentToken.Kind));
          {$ELSE}
          mKind := TRttiEnumerationType.GetName(mLexer.CurrentToken.Kind);
          {$ENDIF}
        {$ENDIF}
          Writeln(Format('token kind = %s: %s @ pos = %d',
          [mKind, mLexer.CurrentToken.Value, mLexer.CurrentToken.StartPos]));
          Continue;
        End;
        Writeln(Format('[ERROR] Illegal token "%s" found at pos %d.',
        [mLexer.CurrentToken.Value, mLexer.CurrentToken.StartPos]));
      Until mLexer.CurrentChar = #0;
      TLexer_Destroy(mLexer);
    End;
  TestParser:
      //mSource := '6 + 7*  ABC )(*+/)2 ! 4784378@ - 738) *(877(9';
      //mSource := '8+/2';
      //mSource := '2*9+(21-1*7)/2';
      //mSource := '3';
      //mSource := '8@';
    While True Do
    Begin
      Readln(mSource);
      //mSource := '(1)';
      If mSource = '' Then
      Begin
        Goto TestLexer;
      End;
      mLexer := TLexer_Create(mSource);
      TLexer_AddRule(mLexer, EofRule.Compose());
      TLexer_AddRule(mLexer, AddRule.Compose());
      TLexer_AddRule(mLexer, SubRule.Compose());
      TLexer_AddRule(mLexer, MulRule.Compose());
      TLexer_AddRule(mLexer, DivRule.Compose());
      TLexer_AddRule(mLexer, LParentRule.Compose());
      TLexer_AddRule(mLexer, RParentRule.Compose());
      TLexer_AddRule(mLexer, NumRule.Compose());
      mParser := TParser_Create(mLexer, ExprRuleUnit.ExprRule);
      If TParser_Parse(mParser) Then
        Writeln('ACCEPTED')
      Else
        Writeln('ERROR');
      OutputAST(mParser.Ast);
      Writeln;
      TParser_Destroy(mParser);
      TLexer_Destroy(mLexer);
    End;
End;

End.
