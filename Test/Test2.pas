Unit Test2;

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
 {$IFDEF USE_STRINGS}strings,{$ENDIF}SysUtils, Lexer, PARSER, GRMRVIWR, GrmRUnit, ASTNode, TestUtil,
  GLEXER, GPARSER, STREAM;

Procedure Test;
Var
  mSource: PStream;
  mGrammarLexer: PLexer;
  mParser: PGrammarParser;
  mViewer: PAstViewer;
Begin
  mSource := PropmtForFile('Grammar File Path? (Default = t.xg)', 't.xg');
  mGrammarLexer := PLexer(GetGrammarLexer(mSource));
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

  TAstViewer_Create(mViewer);
  mParser^.Ast^.VMT^.Accept(mParser^.Ast, mViewer^.As_IAstVisitor);
  TAstViewer_Destroy(mViewer);
  Dispose(mViewer);

  Writeln;
  TGrammarParser_Destroy(PParser(mParser));
  Dispose(mParser);
  mGrammarLexer^.VMT^.Destory(mGrammarLexer);
  Dispose(mGrammarLexer);
  Dispose(mSource);
End;

End.
