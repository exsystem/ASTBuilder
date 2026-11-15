Unit Test3;

{$I define.inc}

Interface

Procedure Test;

Implementation

Uses {$IFNDEF FPC}
  {$IFDEF CLASSIC}
  TypInfo
  {$ELSE}
  System.Rtti
  {$ENDIF}
  , {$ENDIF}
  Stack,
  SysUtils,
  TestUtil,
  Lexer,
  CPARSER,
  Parser, GrmRUnit, ASTNode, ParseTr,
 {$IFDEF USE_STRINGS}strings,{$ENDIF} STREAM, GLEXER, GPARSER, CLEXER, GRMRNODE, TYPEDEF, StrUtil;

Var
  mHereDocId: PTChar;

Procedure TCodeLexer_Init(Var Self: PCodeLexer);
{$IFDEF VINTAGE} Far; {$ENDIF}
Var
  mName: PTChar;
Begin
  mName := TCharStrNew('@HEREDOC_END');
  TGrammarNode_RegisterTermRule(Self^.GrammarNode, mName);
  FreeStr(mName);
End;

Procedure TCodeLexer_ProcessToken(Var Self: PCodeLexer);
{$IFDEF VINTAGE} Far; {$ENDIF}
Var
  mMode: PTChar;
  mTokenValue: PTChar;
  mKind: PTChar;
  mTokenPrefix: PTChar;
  mEndKindName: PTChar;
  mIsHereDocEnd: Boolean;
Begin
  mMode := PPTChar(TStack_Top(Self^.Mode))^;
  mTokenValue := Self^.Parent.CurrentToken.Value;
  mKind := TGrammarNode_GetTermRuleName(Self^.GrammarNode,
    PTermRule(Self^.Parent.CurrentToken.Kind)^);

  If TCharStrComp(mMode, 'hereDoc') <> 0 Then
  Begin
    Exit;
  End;
  If TCharStrComp(mKind, 'START_HEREDOC') = 0 Then
  Begin
    mHereDocId := SubStr(mTokenValue, 3, TCharStrLen(mTokenValue) - 3);
    Exit;
  End;
  If TCharStrComp(mKind, 'HEREDOC_TEXT') = 0 Then
  Begin
    mIsHereDocEnd := False;
    If (mHereDocId <> nil) And
      (TCharStrLen(mTokenValue) >= TCharStrLen(mHereDocId)) Then
    Begin
      mTokenPrefix := SubStr(mTokenValue, 0, TCharStrLen(mHereDocId));
      mIsHereDocEnd := TCharStrComp(mTokenPrefix, mHereDocId) = 0;
      FreeStr(mTokenPrefix);
    End;
    If mIsHereDocEnd Then
    Begin
      mEndKindName := TCharStrNew('@HEREDOC_END');
      PTermRule(Self^.Parent.CurrentToken.Kind)^ :=
        TGrammarNode_GetTermRuleId(Self^.GrammarNode, mEndKindName);
      FreeStr(mEndKindName);
      TLexer_Retract(PLexer(Self), TCharStrLen(Self^.Parent.CurrentToken.Value) -
        TCharStrLen(mHereDocId));
      FreeStr(Self^.Parent.CurrentToken.Value);
      Self^.Parent.CurrentToken.Value := TCharStrNew(mHereDocId);
      TCodeLexer_PopMode(PLexer(Self));
      FreeStr(mHereDocId);
    End;
    Exit;
  End;
End;

Procedure Test;
Var
  mGrammar: PStream;
  mCode: PStream;
  mGrammarLexer: PLexer;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
  mParser: PGrammarParser;
  mViewer: PAstViewer;
  mLexer: PCodeLexer;
  mErrorNode: PNode;
Begin
  mGrammar := PropmtForFile('Grammar File Path? (Default = t.xg)', 't.xg');
  mCode := PropmtForFile('Source Code File Path? (Default = t.pp)', 't.pp');

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
  mLexer^.OnInit := TCodeLexer_Init;
  mLexer^.OnProcessToken := TCodeLexer_ProcessToken;
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
        WriteLn(TCharStrToAnsiString(PTChar(mErrorNode^.Data^)));
        mErrorNode := mErrorNode^.Next;
      End;
    End;
  End;
  TAstViewer_PrintParseTree(mViewer, mViewer^.FParseTree);
  TAstViewer_OutputParseTree(mViewer, '_');
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
