Unit Main;

{$I define.inc}

Interface

Type
  TRegisterTermRule = Procedure(Name: PChar);
  TGetMode = Function: PChar;
  TGetTokenKind = Function: PChar;
  TGetTokenValue = Function: PChar;
  TInsertToken = Procedure(Kind: PChar; Value: PChar);
  TPopMode = Procedure;

  PContext = ^TContext;

  TContext = Record
    RegisterTermRule: TRegisterTermRule;
    GetMode: TGetMode;
    GetTokenKind: TGetTokenKind;
    GetTokenValue: TGetTokenValue;
    InsertToken: TInsertToken;
    PopMode: TPopMode;
  End;

  TInit = Procedure(Context: PContext);
  TProcessToken = Procedure(Context: PContext);

Procedure RegisterTermRule(Name: PChar);
Function GetMode: PChar;
Function GetTokenKind: PChar;
Function GetTokenValue: PChar;
Procedure InsertToken(Kind: PChar; Value: PChar);
Procedure PopMode;

Procedure Run;

Implementation

Uses {$IFNDEF FPC}
  {$IFDEF CLASSIC}
  TypInfo
  {$ELSE}
  System.Rtti
  {$ENDIF}
  , {$ENDIF}
  {$IFDEF FPC}
  dynlibs,
  {$ENDIF}
  {$IFDEF VINTAGE}
  WINPROCS,
  WINTYPES,
  {$ENDIF}
  Stack,
  SysUtils,
  TestUtil,
  Lexer,
  CPARSER,
  Parser, GrmRUnit, ASTNode, ParseTr,
 {$IFDEF USE_STRINGS}strings,{$ENDIF} STREAM, GLEXER, GPARSER, CLEXER, GRMRNODE, TYPEDEF, StrUtil;

Var
  {$IFDEF FPC}
  mHandle: TLibHandle;
  {$ELSE}
  mHandle: THandle;
  {$ENDIF}
  mContext: TContext;
  mLexer: PCodeLexer;

Procedure TCodeLexer_Init(Var Self: PCodeLexer);
{$IFDEF VINTAGE} Far; {$ENDIF}
Var
  mInit: TInit;
  {$IFDEF VINTAGE}
  p: TFarProc;
  {$ENDIF}
Begin
  {$IFDEF VINTAGE}
  p := GetProcAddress(mHandle, 'Init');
  mInit := TInit(p);
  {$ELSE}
  mInit := TInit(GetProcAddress(mHandle, 'Init'));
  {$ENDIF}
  mInit(@mContext);
End;

Procedure TCodeLexer_ProcessToken(Var Self: PCodeLexer);
{$IFDEF VINTAGE} Far; {$ENDIF}
Var
  mProcessToken: TProcessToken;
  {$IFDEF VINTAGE}
  p: TFarProc;
  {$ENDIF}
Begin
  {$IFDEF VINTAGE}
  p := GetProcAddress(mHandle, 'ProcessToken');
  mProcessToken := TProcessToken(p);
  {$ELSE}
  mProcessToken := TProcessToken(GetProcAddress(mHandle, 'ProcessToken'));
  {$ENDIF}
  mProcessToken(@mContext);
End;

Procedure RegisterTermRule(Name: PChar);
Begin
  TGrammarNode_RegisterTermRule(mLexer^.GrammarNode, Name);
End;

Function GetMode: PChar;
Begin
  Result := PPChar(TStack_Top(mLexer^.Mode))^;
End;

Function GetTokenKind: PChar;
Begin
  Result := TGrammarNode_GetTermRuleName(mLexer^.GrammarNode,
    PTermRule(mLexer^.Parent.CurrentToken.Kind)^);
End;

Function GetTokenValue: PChar;
Begin
  Result := mLexer^.Parent.CurrentToken.Value;
End;

Procedure InsertToken(Kind: PChar; Value: PChar);
Begin
  PTermRule(mLexer^.Parent.CurrentToken.Kind)^ :=
    TGrammarNode_GetTermRuleId(mLexer^.GrammarNode, Kind);
  TLexer_Retract(PLexer(mLexer), StrLen(mLexer^.Parent.CurrentToken.Value) -
    StrLen(Value));
  FreeStr(mLexer^.Parent.CurrentToken.Value);
  mLexer^.Parent.CurrentToken.Value := StrNew(Value);
End;

Procedure PopMode;
Begin
  TCodeLexer_PopMode(PLexer(mLexer));
End;

Function PropmtForFile(Prompt: PChar): PStream;
Var
  mFilePath: String;
Begin
  WriteLn(Prompt);
  ReadLn(mFilePath);
  TFileStream_Create(PFileStream(Result), mFilePath);
End;

Procedure Run;
Var
  mGrammar: PStream;
  mCode: PStream;
  mAstPathPrefix: String;
  mPlugInPath: String;
  {$IFDEF VINTAGE}
  p: PChar;
  {$ENDIF}
  mGrammarLexer: PLexer;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
  mParser: PGrammarParser;
  mViewer: PAstViewer;
  mErrorNode: PNode;
Begin
  mPlugInPath := '';
  If (ParamCount = 3) Or (ParamCount = 4) Then
  Begin
    TFileStream_Create(PFileStream(mGrammar), ParamStr(1));
    TFileStream_Create(PFileStream(mCode), ParamStr(2));
    mAstPathPrefix := ParamStr(3);
    If ParamCount = 4 Then
    Begin
      mPlugInPath := ParamStr(4);
    End;
  End
  Else
  Begin
    mGrammar := PropmtForFile('Grammar File Path?');
    mCode := PropmtForFile('Source Code File Path?');
    WriteLn('AST Output Path Prefix?');
    ReadLn(mAstPathPrefix);
    WriteLn('PlugIn Library File Path?');
    ReadLn(mPlugInPath);
  End;

  mGrammarLexer := PLexer(GetGrammarLexer(mGrammar));
  TGrammarParser_Create(mParser, mGrammarLexer, GrammarRule);
  If TGrammarParser_Parse(mParser) Then
    WriteLn('ACCEPTED')
  Else
  Begin
    WriteLn(Format('ERROR: Parser Message: %s', [mParser^.Parent.Error]));
    WriteLn(Format('ERROR: Current Token at Pos = %d, Value = [%s], Message: %s',
      [mGrammarLexer^.CurrentToken.StartPos, mGrammarLexer^.CurrentToken.Value,
      mGrammarLexer^.CurrentToken.Error]));
  End;

  TCodeLexer_Create(mLexer, mCode);
  If mPlugInPath <> '' Then
  Begin
    {$IFDEF VINTAGE}
    GetMem(p, Length(mPlugInPath) + 1);
    StrPCopy(p, mPlugInPath);
    mHandle := LoadLibrary(p);
    FreeMem(p, Length(mPlugInPath) + 1);
    {$ELSE}
    mHandle := LoadLibrary(mPlugInPath);
    {$ENDIF}
    mContext.RegisterTermRule := RegisterTermRule;
    mContext.GetMode := GetMode;
    mContext.GetTokenKind := GetTokenKind;
    mContext.GetTokenValue := GetTokenValue;
    mContext.InsertToken := InsertToken;
    mContext.PopMode := PopMode;
    mLexer^.OnInit := TCodeLexer_Init;
    mLexer^.OnProcessToken := TCodeLexer_ProcessToken;
  End;
  TAstViewer_Create(mViewer, PLexer(mLexer));
  mParser^.Ast^.VMT^.Accept(mParser^.Ast, mViewer^.As_IAstVisitor);
  mViewer^.Level := 0;
  If mViewer^.Error Then
  Begin
    mErrorNode := mViewer^.ErrorMessages^.Top;
    If mErrorNode <> nil Then
    Begin
      While mErrorNode^.Next <> nil Do
      Begin
        WriteLn(PChar(mErrorNode^.Data^));
        mErrorNode := mErrorNode^.Next;
      End;
    End;
  End;
  TAstViewer_OutputParseTree(mViewer, mAstPathPrefix);
  If mPlugInPath <> '' Then
  Begin
    FreeLibrary(mHandle);
  End;
  TParseTree_Destroy(mViewer^.FParseTree);
  TAstViewer_Destroy(PParser(mViewer));
  Dispose(mViewer);
  TCodeLexer_Destroy(PLexer(mLexer));
  Dispose(mLexer);
  TGrammarParser_Destroy(PParser(mParser));
  Dispose(mParser);
  TGrammarLexer_Destroy(mGrammarLexer);
  Dispose(mGrammarLexer);
  Dispose(mGrammar);
  Dispose(mCode);
End;

End.
