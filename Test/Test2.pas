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
  SysUtils, Lexer, Parser, GrmrViwr, GrmRUnit, ASTNode, TestUtil,
 {$IFDEF USE_STRINGS}strings,{$ENDIF} StrUtils;

Procedure Test;
Var
  mSource: PChar;
  mGrammarLexer: PLexer;
  mParser: PParser;
  mViewer: PAstViewer;
Begin
  mSource := PropmtForFile('Grammar File Path? (Default = t.xg)', 't.xg');
  mGrammarLexer := GetGrammarLexer(mSource);
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

  TAstViewer_Create(mViewer);
  mParser^.Ast^.VMT^.Accept(mParser^.Ast, PAstVisitor(mViewer));
  TAstViewer_Destroy(PAstVisitor(mViewer));
  Dispose(mViewer);

  Writeln;
  TParser_Destroy(mParser);
  TLexer_Destroy(mGrammarLexer);
  FreeStr(mSource);
End;

End.
