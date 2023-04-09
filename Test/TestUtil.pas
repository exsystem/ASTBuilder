Unit TestUtil;

{$I define.inc}

Interface

Uses
  {$IFDEF VINTAGE}WinCrt, {$ENDIF} Lexer;

Function ReadTextFileToString(Path: String): PChar;
Function PropmtForFile(Prompt: PChar; DefaultFilePath: PChar): PChar;
Function GetGrammarLexer(Grammar: PChar): PLexer;

Implementation

Uses
  EofRule, IdRule, TermRule, LParRule, OrRule, ColnRule, AstkRule,
  QMrkRule, PlusRule, TildRule, RParRule, LBrkRule,
  RBrkRule, CharRule, ChStRule, StrRule, DotRule, DDtsRule, SemiRule, SkipRule, SysUtils,
 {$IFDEF USE_STRINGS}strings,{$ENDIF} StrUtil;

Function ReadTextFileToString(Path: String): PChar;
Var
  mFile: TextFile;
  mLine: String;
  pLine: PChar;
Begin
  AssignFile(mFile, Path);
  Reset(mFile);
  Result := StrNew('');
  While Not EOF(mFile) Do
  Begin
    ReadLn(mFile, mLine);
    pLine := CreateStr(Length(mLine));
    StrPCopy(pLine, mLine);
    Result := ReallocStr(Result, StrLen(Result) + Length(mLine));
    StrCat(Result, pLine);
    FreeStr(pLine);
  End;
  CloseFile(mFile);
End;

Function PropmtForFile(Prompt: PChar; DefaultFilePath: PChar): PChar;
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
  mFilePath := '..\..\Test\TestCase\' + mFilePath;
  {$IFDEF VER150}
  mFilePath := 'Test/TestCase/' + mFilePath;
  {$ENDIF}
  {$IFDEF VER80}
  mFilePath := 'Test/TestCase/' + mFilePath;
  {$ENDIF}
  {$ENDIF}
  {$IFDEF FPC}
  mFilePath := 'Test/TestCase/' + mFilePath;
  {$ENDIF}
  Result := ReadTextFileToString(mFilePath);
End;

Function GetGrammarLexer(Grammar: PChar): PLexer;
Begin
  Result := TLexer_Create(Grammar, True);
  TLexer_AddRule(Result, EofRule.Compose);
  TLexer_AddRule(Result, IdRule.Compose);
  TLexer_AddRule(Result, TermRule.Compose);
  TLexer_AddRule(Result, LParRule.Compose);
  TLexer_AddRule(Result, OrRule.Compose);
  TLexer_AddRule(Result, ColnRule.Compose);
  TLexer_AddRule(Result, AstkRule.Compose);
  TLexer_AddRule(Result, QMrkRule.Compose);
  TLexer_AddRule(Result, TildRule.Compose);
  TLexer_AddRule(Result, RParRule.Compose);
  TLexer_AddRule(Result, DDtsRule.Compose);
  TLexer_AddRule(Result, CharRule.Compose);
  TLexer_AddRule(Result, ChStRule.Compose);
  TLexer_AddRule(Result, StrRule.Compose);
  TLexer_AddRule(Result, DotRule.Compose);
  TLexer_AddRule(Result, LBrkRule.Compose);
  TLexer_AddRule(Result, RBrkRule.Compose);
  TLexer_AddRule(Result, PlusRule.Compose);
  TLexer_AddRule(Result, TildRule.Compose);
  TLexer_AddRule(Result, SemiRule.Compose);
  TLexer_AddRule(Result, SkipRule.Compose);
End;

End.
