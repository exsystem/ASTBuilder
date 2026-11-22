Unit Main;

{$I define.inc}

Interface

Uses
  LEXER, TypeDef;

Type
  {$IFDEF CLASSIC}
  TSize = TypeDef.TSize;
  PSize = TypeDef.PSize;
  {$ENDIF}

  TRegisterTermRule = Procedure(Name: PTChar);
  TGetMode = Function: PTChar;
  TGetTokenKind = Function: PTChar;
  TGetTokenValue = Function: PTChar;
  TInsertToken = Procedure(Kind: PTChar; Value: PTChar);
  TPopMode = Procedure;

  PContext = ^TContext;

  TContext = Record
    RegisterTermRule: TRegisterTermRule;
    GetMode: TGetMode;
    GetTokenKind: TGetTokenKind;
    GetTokenValue: TGetTokenValue;
    InsertToken: TInsertToken;
    PopMode: TPopMode;
    Encoding: Byte;
  End;

  TInit = Procedure(Context: PContext);
  TProcessToken = Procedure(Context: PContext);

Procedure RegisterTermRule(Name: PTChar);
Function GetMode: PTChar;
Function GetTokenKind: PTChar;
Function GetTokenValue: PTChar;
Procedure InsertToken(Kind: PTChar; Value: PTChar);
Procedure PopMode;

Function Parse(GrammarFile: String; SourceCodeFile: String; AstPathPrefix: String;
  ErrorToken: PToken; ErrorMessages: PString; ErrorMessagesCount: PSize;
  PlugInPath: String): String;
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
  {$ELSE}
  {$IFDEF VINTAGE}
  WINPROCS,
  WINTYPES,
  {$ELSE}
  Windows,
  {$ENDIF}
  {$ENDIF}
  Stack,
  SysUtils,
  TestUtil,
  CPARSER,
  PARSER, GrmRUnit, ASTNode, ParseTr,
 {$IFDEF USE_STRINGS}strings,{$ENDIF} STREAM, StreamReader, GLEXER, GPARSER, CLEXER, GRMRNODE, StrUtil;

 {$IFNDEF VINTAGE}
 Type
  TSize = TypeDef.TSize;
  PSize = TypeDef.PSize;
 {$ENDIF}

Var
  {$IFDEF FPC}
  mHandle: TLibHandle;
  {$ELSE}
  mHandle: THandle;
  {$ENDIF}
  mContext: TContext;
  mLexer: PCodeLexer;
  mPluginMode: PTChar;
  mPluginTokenKind: PTChar;
  mPluginTokenValue: PTChar;

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

Procedure RegisterTermRule(Name: PTChar);
Var
  mName: PTChar;
Begin
  mName := TCharStrNew(Name);
  Try
    TGrammarNode_RegisterTermRule(mLexer^.GrammarNode, mName);
  Finally
    FreeStr(mName);
  End;
End;

Function GetMode: PTChar;
Begin
  FreeStr(mPluginMode);
  mPluginMode := nil;
  mPluginMode := TCharStrNew(PPTChar(TStack_Top(mLexer^.Mode))^);
  Result := mPluginMode;
End;

Function GetTokenKind: PTChar;
Begin
  FreeStr(mPluginTokenKind);
  mPluginTokenKind := nil;
  mPluginTokenKind := TCharStrNew(
    TGrammarNode_GetTermRuleName(mLexer^.GrammarNode,
      PTermRule(mLexer^.Parent.CurrentToken.Kind)^));
  Result := mPluginTokenKind;
End;

Function GetTokenValue: PTChar;
Begin
  FreeStr(mPluginTokenValue);
  mPluginTokenValue := nil;
  mPluginTokenValue := TCharStrNew(mLexer^.Parent.CurrentToken.Value);
  Result := mPluginTokenValue;
End;

Procedure InsertToken(Kind: PTChar; Value: PTChar);
Var
  mKind, mValue: PTChar;
Begin
  mKind := TCharStrNew(Kind);
  mValue := TCharStrNew(Value);
  Try
    PTermRule(mLexer^.Parent.CurrentToken.Kind)^ :=
      TGrammarNode_GetTermRuleId(mLexer^.GrammarNode, mKind);
    TLexer_Retract(PLexer(mLexer),
      TCharStrLen(mLexer^.Parent.CurrentToken.Value) - TCharStrLen(mValue));
    FreeStr(mLexer^.Parent.CurrentToken.Value);
    mLexer^.Parent.CurrentToken.Value := TCharStrNew(mValue);
  Finally
    FreeStr(mKind);
    FreeStr(mValue);
  End;
End;

Procedure PopMode;
Begin
  TCodeLexer_PopMode(PLexer(mLexer));
End;

Function Propmt(Const Prompt: AnsiString): String;
Begin
  WriteLn(Prompt);
  ReadLn(Result);
End;

Function Parse(GrammarFile: String; SourceCodeFile: String; AstPathPrefix: String;
  ErrorToken: PToken; ErrorMessages: PString; ErrorMessagesCount: PSize;
  PlugInPath: String): String;
Var
  mGrammar: PStream;
  mCode: PStream;
  {$IFDEF VINTAGE}
  p: PTChar;
  {$ENDIF}
  mGrammarLexer: PLexer;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
  mParser: PGrammarParser;
  mViewer: PAstViewer;
  mErrorNode: PNode;
  e: PString;
Begin
  TStreamReader_Create(PStreamReader(mGrammar), GrammarFile);
  TStreamReader_Create(PStreamReader(mCode), SourceCodeFile);

  mGrammarLexer := PLexer(GetGrammarLexer(mGrammar));
  TGrammarParser_Create(mParser, mGrammarLexer, GrammarRule);
  If Not TGrammarParser_Parse(mParser) Then
  Begin
    Result := TCharStrToAnsiString(mParser^.Parent.Error);
    ErrorToken^.StartPos := mGrammarLexer^.CurrentToken.StartPos;
    ErrorToken^.Value := TCharStrNew(mGrammarLexer^.CurrentToken.Value);
    ErrorToken^.Error := TCharStrNew(mGrammarLexer^.CurrentToken.Error);
  End;

  TCodeLexer_Create(mLexer, mCode);
  If PlugInPath <> '' Then
  Begin
    {$IFDEF FPC}
    mHandle := LoadLibrary(PlugInPath);
    {$ELSE}
    {$IFDEF VINTAGE}
    GetMem(p, Length(PlugInPath) + 1);
    StrPCopy(p, PlugInPath);
    mHandle := LoadLibrary(p);
    FreeMem(p, Length(PlugInPath) + 1);
    {$ELSE}
    mHandle := LoadLibrary(PTChar(PlugInPath));
    {$ENDIF}
    {$ENDIF}
    mContext.RegisterTermRule := RegisterTermRule;
    mContext.GetMode := GetMode;
    mContext.GetTokenKind := GetTokenKind;
    mContext.GetTokenValue := GetTokenValue;
    mContext.InsertToken := InsertToken;
    mContext.PopMode := PopMode;
    mContext.Encoding := Ord(TChar_GetGlobalEncoding);
    mLexer^.OnInit := TCodeLexer_Init;
    mLexer^.OnProcessToken := TCodeLexer_ProcessToken;
  End;
  TAstViewer_Create(mViewer, PLexer(mLexer));
  mParser^.Ast^.VMT^.Accept(mParser^.Ast, mViewer^.As_IAstVisitor);
  mViewer^.Level := 0;
  ErrorMessagesCount^ := 0;
  If mViewer^.Error Then
  Begin
    mErrorNode := mViewer^.ErrorMessages^.Top;
    If mErrorNode <> nil Then
    Begin
      While mErrorNode^.Next <> nil Do
      Begin
        Inc(ErrorMessagesCount);
        mErrorNode := mErrorNode^.Next;
      End;
    End;
    GetMem(ErrorMessages, ErrorMessagesCount^ * SizeOf(PString));
    e := ErrorMessages;
    mErrorNode := mViewer^.ErrorMessages^.Top;
    If mErrorNode <> nil Then
    Begin
      While mErrorNode^.Next <> nil Do
      Begin
        e^ := TCharStrToAnsiString(PTChar(mErrorNode^.Data^));
        Inc(e);
        mErrorNode := mErrorNode^.Next;
      End;
    End;
  End;
  TAstViewer_OutputParseTree(mViewer, AstPathPrefix);
  If PlugInPath <> '' Then
  Begin
    FreeLibrary(mHandle);
  End;
  FreeStr(mPluginMode);
  mPluginMode := nil;
  FreeStr(mPluginTokenKind);
  mPluginTokenKind := nil;
  FreeStr(mPluginTokenValue);
  mPluginTokenValue := nil;
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

  Result := '';
End;

Procedure Run;
Var
  mGrammarFilePath: String;
  mSourceCodeFilePath: String;
  mAstPathPrefix: String;
  mPlugInPath: String;
  mResult: String;
  mErrorToken: TToken;
  mErrorMessagesCount: TSize;
  mErrorMessages: PString;
  p: PString;
Begin
  mPlugInPath := '';
  If (ParamCount = 3) Or (ParamCount = 4) Then
  Begin
    mGrammarFilePath := ParamStr(1);
    mSourceCodeFilePath := ParamStr(2);
    mAstPathPrefix := ParamStr(3);
    If ParamCount = 4 Then
    Begin
      mPlugInPath := ParamStr(4);
    End;
  End
  Else
  Begin
    mGrammarFilePath := Propmt('Grammar File Path?');
    mSourceCodeFilePath := Propmt('Source Code File Path?');
    mAstPathPrefix := Propmt('AST Output Path Prefix?');
    mPlugInPath := Propmt('PlugIn Library File Path?');
  End;

  mResult := Parse(mGrammarFilePath, mSourceCodeFilePath, mAstPathPrefix,
    @mErrorToken, mErrorMessages, @mErrorMessagesCount, mPlugInPath);
  If mResult = '' Then
    WriteLn('ACCEPTED')
  Else
  Begin
    WriteLn(Format('ERROR: Parser Message: %s', [mResult]));
    WriteLn(Format('ERROR: Current Token at Pos = %d, Value = [%s], Message: %s',
      [mErrorToken.StartPos, TCharStrToAnsiString(mErrorToken.Value),
      TCharStrToAnsiString(mErrorToken.Error)]));
  End;

  If mErrorMessagesCount > 0 Then
  Begin
    p := mErrorMessages;
    While mErrorMessagesCount > 0 Do
    Begin
      WriteLn(p^);
      Inc(p);
      Dec(mErrorMessagesCount);
    End;
    FreeMem(mErrorMessages, mErrorMessagesCount * SizeOf(PString));
  End;
End;

End.
