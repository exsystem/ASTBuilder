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
  EofRule, IdRule, TermRule, LParenRule, OrRule, ColonRule, AsteriskRule, QuestionMarkRule, 
  RParenRule, SemiRule, GrammarViewer, Parser, GrammarRuleUnit, ASTNode;

Procedure Test1();
Var
  mSource: String;
  mLexer: PLexer;
  mKind: String;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
  mParser: PParser;
  mViewer: PAstViewer;
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
      TLexer_AddRule(mLexer, IdRule.Compose());
      TLexer_AddRule(mLexer, TermRule.Compose());
      TLexer_AddRule(mLexer, LParenRule.Compose());
      TLexer_AddRule(mLexer, OrRule.Compose());
      TLexer_AddRule(mLexer, ColonRule.Compose());
      TLexer_AddRule(mLexer, AsteriskRule.Compose());
      TLexer_AddRule(mLexer, QuestionMarkRule.Compose());
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
    While True Do
    Begin
      Readln(mSource);
      If mSource = '' Then
      Begin
        Goto TestLexer;
      End;
      mLexer := TLexer_Create(mSource);
      TLexer_AddRule(mLexer, EofRule.Compose());
      TLexer_AddRule(mLexer, IdRule.Compose());
      TLexer_AddRule(mLexer, TermRule.Compose());
      TLexer_AddRule(mLexer, LParenRule.Compose());
      TLexer_AddRule(mLexer, OrRule.Compose());
      TLexer_AddRule(mLexer, ColonRule.Compose());
      TLexer_AddRule(mLexer, AsteriskRule.Compose());
      TLexer_AddRule(mLexer, QuestionMarkRule.Compose());
      TLexer_AddRule(mLexer, RParenRule.Compose());
      TLexer_AddRule(mLexer, SemiRule.Compose());
      mParser := TParser_Create(mLexer, GrammarRule);
      If TParser_Parse(mParser) Then
        WriteLn('ACCEPTED')
      Else
      Begin
        WriteLn(Format('ERROR: Parser Message: %s', [mParser.Error]));
        WriteLn(Format('ERROR: Current Token at Pos = %d, Value = [%s], Message: %s',
        [mLexer.CurrentToken.StartPos, mLexer.CurrentToken.Value,
        mLexer.CurrentToken.Error]));
      End;

      TAstViewer_Create(mViewer);
      mParser.Ast.VMT.Accept(mParser.Ast, PAstVisitor(mViewer));
      TAstViewer_Destroy(PAstVisitor(mViewer));
      Dispose(mViewer);

      Writeln;
      TParser_Destroy(mParser);
      TLexer_Destroy(mLexer);
    End;
End;

End.
