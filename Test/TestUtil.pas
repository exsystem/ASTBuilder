Unit TestUtil;

{$I define.inc}

Interface

Uses
  {$IFDEF VINTAGE}WinCrt, {$ENDIF} Lexer, GLexer, Stream;

Function PropmtForFile(Prompt: PChar; DefaultFilePath: PChar): PStream;
Function GetGrammarLexer(Grammar: PStream): PGrammarLexer;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings,{$ENDIF}
  EofRule, IdRule, TermRule, LParRule, OrRule, ColnRule, AstkRule,
  QMrkRule, PlusRule, TildRule, RParRule, LBrkRule,
  RBrkRule, LCBRule, RCBRule, CharRule, ChStRule, StrRule, DotRule,
  DDtsRule, EquRule, SemiRule, SkipRule, OptRule, SysUtils;

Function PropmtForFile(Prompt: PChar; DefaultFilePath: PChar): PStream;
Var
  mFilePath: String;
Begin
  WriteLn(Prompt);
  ReadLn(mFilePath);
  If mFilePath = '' Then
  Begin
    mFilePath := StrPas(DefaultFilePath);
  End;
  {$IFDEF DCC}
  {$IFDEF CLASSIC}
  mFilePath := 'Test\TestCase\' + mFilePath;
  {$ELSE}
  mFilePath := '..\..\Test\TestCase\' + mFilePath;
  {$ENDIF}
  {$ENDIF}
  {$IFDEF FPC}
  mFilePath := 'Test/TestCase/' + mFilePath;
  {$ENDIF}
  TFileStream_Create(PFileStream(Result), mFilePath);
End;

Function GetGrammarLexer(Grammar: PStream): PGrammarLexer;
Var
  mLexer: PLexer;
Begin
  TGrammarLexer_Create(Result, Grammar);
  mLexer := PLexer(Result);
  TGrammarLexer_AddRule(mLexer, EofRule.Compose);
  TGrammarLexer_AddRule(mLexer, OptRule.Compose);
  TGrammarLexer_AddRule(mLexer, IdRule.Compose);
  TGrammarLexer_AddRule(mLexer, TermRule.Compose);
  TGrammarLexer_AddRule(mLexer, LParRule.Compose);
  TGrammarLexer_AddRule(mLexer, OrRule.Compose);
  TGrammarLexer_AddRule(mLexer, ColnRule.Compose);
  TGrammarLexer_AddRule(mLexer, AstkRule.Compose);
  TGrammarLexer_AddRule(mLexer, QMrkRule.Compose);
  TGrammarLexer_AddRule(mLexer, TildRule.Compose);
  TGrammarLexer_AddRule(mLexer, RParRule.Compose);
  TGrammarLexer_AddRule(mLexer, DDtsRule.Compose);
  TGrammarLexer_AddRule(mLexer, CharRule.Compose);
  TGrammarLexer_AddRule(mLexer, ChStRule.Compose);
  TGrammarLexer_AddRule(mLexer, StrRule.Compose);
  TGrammarLexer_AddRule(mLexer, DotRule.Compose);
  TGrammarLexer_AddRule(mLexer, LBrkRule.Compose);
  TGrammarLexer_AddRule(mLexer, RBrkRule.Compose);
  TGrammarLexer_AddRule(mLexer, LCBRule.Compose);
  TGrammarLexer_AddRule(mLexer, RCBRule.Compose);
  TGrammarLexer_AddRule(mLexer, PlusRule.Compose);
  TGrammarLexer_AddRule(mLexer, TildRule.Compose);
  TGrammarLexer_AddRule(mLexer, EquRule.Compose);
  TGrammarLexer_AddRule(mLexer, SemiRule.Compose);
  TGrammarLexer_AddRule(mLexer, SkipRule.Compose);
End;

End.
