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
 {$IFDEF USE_STRINGS}strings,{$ENDIF} STREAM, GLEXER, GPARSER, CLEXER;

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
  TAstViewer_PrintParseTree(mViewer, mViewer^.FParseTree);
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
