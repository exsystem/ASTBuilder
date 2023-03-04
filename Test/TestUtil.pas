Unit TestUtil;

{$I define.inc}

Interface

Uses
  Lexer;

Function ReadTextFileToString(Path: String): PChar;
Function PropmtForFile(Prompt: PChar; DefaultFilePath: PChar): PChar;
Function GetGrammarLexer(Grammar: PChar): PLexer;

Implementation

Uses
  EofRule, IdRule, TermRule, LParenRule, OrRule, ColonRule, AsteriskRule,
  QuestionMarkRule, PlusRule, TildeRule, RParenRule, LBracketRule,
  RBracketRule, CharRule, StringRule, DoubleDotsRule, SemiRule, SkipRule, SysUtils,
 {$IFDEF USE_STRINGS}strings,{$ENDIF} StringUtils;

Function ReadTextFileToString(Path: String): PChar;
Var
  mFile: TextFile;
  mLine: String;
Begin
  AssignFile(mFile, Path);
  Reset(mFile);
  Result := StrNew('');
  While Not EOF(mFile) Do
  Begin
    ReadLn(mFile, mLine);
    Result := ReallocStr(Result, StrLen(Result) + StrLen(PChar(mLine)));
    StrCat(Result, PChar(mLine));
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
    mFilePath := DefaultFilePath;
  End;
  {$IFDEF DCC}
  mFilePath := '..\..\Test\TestCase\' + mFilePath;
  {$ENDIF}
  {$IFDEF FPC}
  mFilePath := 'Test/TestCase/' + mFilePath;
  {$ENDIF}
  Result := ReadTextFileToString(mFilePath);
End;

Function GetGrammarLexer(Grammar: PChar): PLexer;
Begin
  Result := TLexer_Create(Grammar);
  TLexer_AddRule(Result, EofRule.Compose());
  TLexer_AddRule(Result, IdRule.Compose());
  TLexer_AddRule(Result, TermRule.Compose());
  TLexer_AddRule(Result, LParenRule.Compose());
  TLexer_AddRule(Result, OrRule.Compose());
  TLexer_AddRule(Result, ColonRule.Compose());
  TLexer_AddRule(Result, AsteriskRule.Compose());
  TLexer_AddRule(Result, QuestionMarkRule.Compose());
  TLexer_AddRule(Result, TildeRule.Compose());
  TLexer_AddRule(Result, RParenRule.Compose());
  TLexer_AddRule(Result, DoubleDotsRule.Compose());
  TLexer_AddRule(Result, CharRule.Compose());
  TLexer_AddRule(Result, StringRule.Compose());
  TLexer_AddRule(Result, LBracketRule.Compose());
  TLexer_AddRule(Result, RBracketRule.Compose());
  TLexer_AddRule(Result, PlusRule.Compose());
  TLexer_AddRule(Result, TildeRule.Compose());
  TLexer_AddRule(Result, SemiRule.Compose());
  TLexer_AddRule(Result, SkipRule.Compose());
End;

End.
