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
  SlashRule,
  EofRule,
  LParentRule,
  MulRule,
  NumRule,
  RParentRule,
  SubRule,
  NotRule,
  DivRule,
  ModRule,
  AndRule,
  ShlRule,
  ShrRule,
  AsRule,
  OrRule,
  XorRule,
  EqualRule,
  NotEqualRule,
  LTRule,
  GTRule,
  LERule,
  GERule,
  InRule,
  IsRule;

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
      TLexer_AddRule(mLexer, NotRule.Compose());
      TLexer_AddRule(mLexer, AddRule.Compose());
      TLexer_AddRule(mLexer, SubRule.Compose());
      TLexer_AddRule(mLexer, MulRule.Compose());
      TLexer_AddRule(mLexer, SlashRule.Compose());
      TLexer_AddRule(mLexer, DivRule.Compose());
      TLexer_AddRule(mLexer, ModRule.Compose());
      TLexer_AddRule(mLexer, AndRule.Compose());
      TLexer_AddRule(mLexer, ShlRule.Compose());
      TLexer_AddRule(mLexer, ShrRule.Compose());
      TLexer_AddRule(mLexer, AsRule.Compose());
      TLexer_AddRule(mLexer, OrRule.Compose());
      TLexer_AddRule(mLexer, XorRule.Compose());
      TLexer_AddRule(mLexer, EqualRule.Compose());
      TLexer_AddRule(mLexer, NotEqualRule.Compose());
      TLexer_AddRule(mLexer, LTRule.Compose());
      TLexer_AddRule(mLexer, GTRule.Compose());
      TLexer_AddRule(mLexer, LERule.Compose());
      TLexer_AddRule(mLexer, GERule.Compose());
      TLexer_AddRule(mLexer, InRule.Compose());
      TLexer_AddRule(mLexer, IsRule.Compose());
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
      Until TLexer_PeekNextChar(mLexer) = #0;
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
      TLexer_AddRule(mLexer, SlashRule.Compose());
      TLexer_AddRule(mLexer, LParentRule.Compose());
      TLexer_AddRule(mLexer, RParentRule.Compose());
      TLexer_AddRule(mLexer, NumRule.Compose());
      mParser := TParser_Create(mLexer, ExprRuleUnit.ExprRule);
      If TParser_Parse(mParser) Then
        WriteLn('ACCEPTED')
      Else
      Begin
        WriteLn(Format('ERROR: Parser Message: %s', [mParser.Error]));
        WriteLn(Format('ERROR: Current Token at Pos = %d, Value = [%s], Message: %s',
        [mLexer.CurrentToken.StartPos, mLexer.CurrentToken.Value,
        mLexer.CurrentToken.Error]));
      End;
      OutputAST(mParser.Ast);
      Writeln;
      TParser_Destroy(mParser);
      TLexer_Destroy(mLexer);
    End;
End;

End.
