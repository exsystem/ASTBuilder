Unit Test3;

{$I define.inc}

Interface

Type
  PPInteger = ^PInteger;

Procedure Test();

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
  EofRule, IdRule, TermRule, LParenRule, OrRule, ColonRule, AsteriskRule,
  QuestionMarkRule,
  RParenRule, CharRule, StringRule, DoubleDotsRule, SemiRule, GrammarParser,
  Parser, GrammarRuleUnit, ASTNode, ParseTree, TypeDef,
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

Procedure Test();
Var
  mGrammarFilePath: String;
  mGrammar: PChar;
  mCodeFilePath: String;
  mCode: PChar;
  mGrammarLexer: PLexer;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
  mParser: PParser;
  mViewer: PAstViewer;
  mLexer: PLexer;
Begin
  WriteLn('Grammar File Path?');
  ReadLn(mGrammarFilePath);
  If mGrammarFilePath = '' Then
  Begin
    mGrammarFilePath := '/Users/exsystem/testfile/pas.xg';
  End;
  mGrammar := ReadTextFileToString(mGrammarFilePath);

  WriteLn('Code File Path?');
  ReadLn(mCodeFilePath);
  If mCodeFilePath = '' Then
  Begin
    mCodeFilePath := '/Users/exsystem/testfile/test.pas';
  End;
  mCode := ReadTextFileToString(mCodeFilePath);

  mGrammarLexer := TLexer_Create(mGrammar);
  TLexer_AddRule(mGrammarLexer, EofRule.Compose());
  TLexer_AddRule(mGrammarLexer, IdRule.Compose());
  TLexer_AddRule(mGrammarLexer, TermRule.Compose());
  TLexer_AddRule(mGrammarLexer, LParenRule.Compose());
  TLexer_AddRule(mGrammarLexer, OrRule.Compose());
  TLexer_AddRule(mGrammarLexer, ColonRule.Compose());
  TLexer_AddRule(mGrammarLexer, AsteriskRule.Compose());
  TLexer_AddRule(mGrammarLexer, QuestionMarkRule.Compose());
  TLexer_AddRule(mGrammarLexer, RParenRule.Compose());
  TLexer_AddRule(mGrammarLexer, DoubleDotsRule.Compose());
  TLexer_AddRule(mGrammarLexer, CharRule.Compose());
  TLexer_AddRule(mGrammarLexer, StringRule.Compose());
  TLexer_AddRule(mGrammarLexer, SemiRule.Compose());

  mParser := TParser_Create(mGrammarLexer, GrammarRule);
  If TParser_Parse(mParser) Then
    WriteLn('ACCEPTED')
  Else
  Begin
    WriteLn(Format('ERROR: Parser Message: %s', [mParser.Error]));
    WriteLn(Format('ERROR: Current Token at Pos = %d, Value = [%s], Message: %s',
      [mGrammarLexer.CurrentToken.StartPos, mGrammarLexer.CurrentToken.Value,
      mGrammarLexer.CurrentToken.Error]));
  End;

  mLexer := TLexer_Create(mCode, False);
  TAstViewer_Create(mViewer, mLexer);
  mParser.Ast.VMT.Accept(mParser.Ast, PAstVisitor(mViewer));
  mViewer.Level := 0;
  WriteLn(mViewer.Error);
  TAstViewer_PrintParseTree(PAstVisitor(mViewer), mViewer.FParseTree);
  TParseTree_Destroy(mViewer.FParseTree);
  TAstViewer_Destroy(PAstVisitor(mViewer));
  Dispose(mViewer);
  TLexer_Destroy(mLexer);
  TParser_Destroy(mParser);
  TLexer_Destroy(mGrammarLexer);
  FreeStr(mGrammar);
  FreeStr(mCode);
  ReadLn;
End;

End.
