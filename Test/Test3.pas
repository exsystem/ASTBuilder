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
  GrmrPasr,
  Parser, GrmRUnit, ASTNode, ParseTr,
 {$IFDEF USE_STRINGS}strings,{$ENDIF} StrUtils;

Procedure Test;
Var
  mGrammar: PChar;
  mCode: PChar;
  mGrammarLexer: PLexer;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
  mParser: PParser;
  mViewer: PAstViewer;
  mLexer: PLexer;
  mErrorNode: PNode;
Begin
  mGrammar := PropmtForFile('Grammar File Path? (Default = t.xg)', 't.xg');
  mCode := PropmtForFile('Source Code File Path? (Default = t.pp)', 't.pp');

  mGrammarLexer := GetGrammarLexer(mGrammar);
  mParser := TParser_Create(mGrammarLexer, GrammarRule);
  If TParser_Parse(mParser) Then
    WriteLn('ACCEPTED')
  Else
  Begin
    WriteLn(Format('ERROR: Parser Message: %s', [mParser^.Error]));
    WriteLn(Format('ERROR: Current Token at Pos = %d, Value = [%s], Message: %s',
      [mGrammarLexer^.CurrentToken.StartPos, mGrammarLexer^.CurrentToken.Value,
      mGrammarLexer^.CurrentToken.Error]));
  End;

  mLexer := TLexer_Create(mCode, False);
  TAstViewer_Create(mViewer, mLexer);
  mParser^.Ast^.VMT^.Accept(mParser^.Ast, PAstVisitor(mViewer));
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
  TAstViewer_PrintParseTree(PAstVisitor(mViewer), mViewer^.FParseTree);
  TParseTree_Destroy(mViewer^.FParseTree);
  TAstViewer_Destroy(PAstVisitor(mViewer));
  Dispose(mViewer);
  TLexer_Destroy(mLexer);
  TParser_Destroy(mParser);
  TLexer_Destroy(mGrammarLexer);
  FreeStr(mGrammar);
  FreeStr(mCode);
End;

End.
