Unit Main;

{$I define.inc}

Interface

Uses
  Lexer, TypeDef;

Type
  {$IFDEF CLASSIC}
  TSize = TypeDef.TSize;
  PSize = TypeDef.PSize;
  {$ENDIF}

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
  Parser, GrmRUnit, ASTNode, ParseTr,
 {$IFDEF USE_STRINGS}strings,{$ENDIF} STREAM, GLEXER, GPARSER, CLEXER, GRMRNODE, StrUtil;

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

Function Propmt(Prompt: PChar): String;
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
  p: PChar;
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
  TFileStream_Create(PFileStream(mGrammar), GrammarFile);
  TFileStream_Create(PFileStream(mCode), SourceCodeFile);

  mGrammarLexer := PLexer(GetGrammarLexer(mGrammar));
  TGrammarParser_Create(mParser, mGrammarLexer, GrammarRule);
  If Not TGrammarParser_Parse(mParser) Then
  Begin
    Result := Format('%s', [mParser^.Parent.Error]);
    ErrorToken.StartPos := mGrammarLexer^.CurrentToken.StartPos;
    ErrorToken.Value := strnew(mGrammarLexer^.CurrentToken.Value);
    ErrorToken.Error := strnew(mGrammarLexer^.CurrentToken.Error);
  End;

  TCodeLexer_Create(mLexer, mCode);
  If PlugInPath <> '' Then
  Begin
    {$IFDEF FPC}
    mHandle := LoadLibrary(PlugInPath);
    {$ELSE}
    {$IFDEF VINTAGE}
    GetMem(p, Length(mPlugInPath) + 1);
    StrPCopy(p, mPlugInPath);
    mHandle := LoadLibrary(p);
    FreeMem(p, Length(mPlugInPath) + 1);
    {$ELSE}
    mHandle := LoadLibrary(PChar(mPlugInPath));
    {$ENDIF}
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
        e^ := Format('%s', [PChar(mErrorNode^.Data^)]);
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
      [mErrorToken.StartPos, mErrorToken.Value, mErrorToken.Error]));
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
