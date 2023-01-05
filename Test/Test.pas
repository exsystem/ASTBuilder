Unit Test;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Type
  PPInteger = ^PInteger;

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
  EofRule, IdRule, LParenRule, OrRule, ProduceRule, RepeatRule, RootRule,
  RParenRule, SemiRule;

Procedure Test1();
Var
  mSource: String;
  mLexer: PLexer;
  mKind: String;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
Label
  TestLexer, TestParser;
Begin
  Goto TestLexer;

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
      TLexer_AddRule(mLexer, IdRule.Compose());
      TLexer_AddRule(mLexer, LParenRule.Compose());
      TLexer_AddRule(mLexer, OrRule.Compose());
      TLexer_AddRule(mLexer, ProduceRule.Compose());
      TLexer_AddRule(mLexer, RepeatRule.Compose());
      TLexer_AddRule(mLexer, RootRule.Compose());
      TLexer_AddRule(mLexer, RParenRule.Compose());
      TLexer_AddRule(mLexer, SemiRule.Compose());
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
    Exit;
End;

End.
