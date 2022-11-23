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
  Parser,
  ASTNode,
  ASTHanyu,
  StmtRuleUnit,
  PlusRule,
  SlashRule,
  EofRule,
  LParentRule,
  MulRule,
  NumRule,
  RParentRule,
  MinusRule,
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
  IsRule,
  IdRule,
  AtRule,
  LBrackRule,
  RBrackRule,
  LBrack2Rule,
  RBrack2Rule,
  CommaRule,
  DotRule,
  PointerRule,
  AssignRule,
  GotoRule,
  ColonRule;

Procedure Test1();
Var
  mSource: String;
  mLexer: PLexer;
  mParser: PParser;
  mKind: String;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
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
      TLexer_AddRule(mLexer, AtRule.Compose());
      TLexer_AddRule(mLexer, PointerRule.Compose());
      TLexer_AddRule(mLexer, NotRule.Compose(mLexer));
      TLexer_AddRule(mLexer, PlusRule.Compose());
      TLexer_AddRule(mLexer, MinusRule.Compose());
      TLexer_AddRule(mLexer, MulRule.Compose());
      TLexer_AddRule(mLexer, SlashRule.Compose());
      TLexer_AddRule(mLexer, DivRule.Compose(mLexer));
      TLexer_AddRule(mLexer, ModRule.Compose(mLexer));
      TLexer_AddRule(mLexer, AndRule.Compose(mLexer));
      TLexer_AddRule(mLexer, ShlRule.Compose(mLexer));
      TLexer_AddRule(mLexer, ShrRule.Compose(mLexer));
      TLexer_AddRule(mLexer, AsRule.Compose(mLexer));
      TLexer_AddRule(mLexer, OrRule.Compose(mLexer));
      TLexer_AddRule(mLexer, XorRule.Compose(mLexer));
      TLexer_AddRule(mLexer, EqualRule.Compose());
      TLexer_AddRule(mLexer, NotEqualRule.Compose());
      TLexer_AddRule(mLexer, LERule.Compose());
      TLexer_AddRule(mLexer, GERule.Compose());
      TLexer_AddRule(mLexer, LTRule.Compose());
      TLexer_AddRule(mLexer, GTRule.Compose());
      TLexer_AddRule(mLexer, InRule.Compose(mLexer));
      TLexer_AddRule(mLexer, IsRule.Compose(mLexer));
      TLexer_AddRule(mLexer, LBrack2Rule.Compose());
      TLexer_AddRule(mLexer, RBrack2Rule.Compose());
      TLexer_AddRule(mLexer, LParentRule.Compose());
      TLexer_AddRule(mLexer, RParentRule.Compose());
      TLexer_AddRule(mLexer, LBrackRule.Compose());
      TLexer_AddRule(mLexer, RBrackRule.Compose());
      TLexer_AddRule(mLexer, CommaRule.Compose());
      TLexer_AddRule(mLexer, DotRule.Compose());
      TLexer_AddRule(mLexer, AssignRule.Compose());
      TLexer_AddRule(mLexer, ColonRule.Compose());
      TLexer_AddRule(mLexer, NumRule.Compose());
      TLexer_AddRule(mLexer, GotoRule.Compose(mLexer));
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
      TLexer_AddRule(mLexer, IdRule.Compose());
      TLexer_AddRule(mLexer, AtRule.Compose());
      TLexer_AddRule(mLexer, PointerRule.Compose());
      TLexer_AddRule(mLexer, NotRule.Compose(mLexer));
      TLexer_AddRule(mLexer, PlusRule.Compose());
      TLexer_AddRule(mLexer, MinusRule.Compose());
      TLexer_AddRule(mLexer, MulRule.Compose());
      TLexer_AddRule(mLexer, SlashRule.Compose());
      TLexer_AddRule(mLexer, DivRule.Compose(mLexer));
      TLexer_AddRule(mLexer, ModRule.Compose(mLexer));
      TLexer_AddRule(mLexer, AndRule.Compose(mLexer));
      TLexer_AddRule(mLexer, ShlRule.Compose(mLexer));
      TLexer_AddRule(mLexer, ShrRule.Compose(mLexer));
      TLexer_AddRule(mLexer, AsRule.Compose(mLexer));
      TLexer_AddRule(mLexer, OrRule.Compose(mLexer));
      TLexer_AddRule(mLexer, XorRule.Compose(mLexer));
      TLexer_AddRule(mLexer, EqualRule.Compose());
      TLexer_AddRule(mLexer, NotEqualRule.Compose());
      TLexer_AddRule(mLexer, LERule.Compose());
      TLexer_AddRule(mLexer, GERule.Compose());
      TLexer_AddRule(mLexer, LTRule.Compose());
      TLexer_AddRule(mLexer, GTRule.Compose());
      TLexer_AddRule(mLexer, InRule.Compose(mLexer));
      TLexer_AddRule(mLexer, IsRule.Compose(mLexer));
      TLexer_AddRule(mLexer, LBrack2Rule.Compose());
      TLexer_AddRule(mLexer, RBrack2Rule.Compose());
      TLexer_AddRule(mLexer, LParentRule.Compose());
      TLexer_AddRule(mLexer, RParentRule.Compose());
      TLexer_AddRule(mLexer, LBrackRule.Compose());
      TLexer_AddRule(mLexer, RBrackRule.Compose());
      TLexer_AddRule(mLexer, CommaRule.Compose());
      TLexer_AddRule(mLexer, DotRule.Compose());
      TLexer_AddRule(mLexer, AssignRule.Compose());
      TLexer_AddRule(mLexer, ColonRule.Compose());
      TLexer_AddRule(mLexer, NumRule.Compose());
      TLexer_AddRule(mLexer, GotoRule.Compose(mLexer));
      mParser := TParser_Create(mLexer, StmtRule);
      If TParser_Parse(mParser) Then
        WriteLn('ACCEPTED')
      Else
      Begin
        WriteLn(Format('ERROR: Parser Message: %s', [mParser.Error]));
        WriteLn(Format('ERROR: Current Token at Pos = %d, Value = [%s], Message: %s',
        [mLexer.CurrentToken.StartPos, mLexer.CurrentToken.Value,
        mLexer.CurrentToken.Error]));
      End;
      //OutputAST(mParser.Ast);

      New(mViewer);
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
