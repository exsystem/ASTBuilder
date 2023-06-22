Unit Test1;

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
 {$IFDEF USE_STRINGS}strings{$ENDIF}
  Lexer,
  GLexer,
  Stream,
  TestUtil,
  SysUtils;

Procedure Test;
Var
  mSource: PStream;
  mLexer: PGrammarLexer;
  mKind: String;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
Begin
  mSource := PropmtForFile('Grammar File Path? (Default = t.xg)', 't.xg');
  mLexer := GetGrammarLexer(mSource);
  Repeat
    If mLexer^.Parent.VMT^.GetNextToken(PLexer(mLexer)) Then
    Begin
        {$IFDEF FPC}
        WriteStr(mKind, PGrammarTokenKind(mLexer^.Parent.CurrentToken.Kind)^);
        {$ENDIF}
        {$IFDEF DCC}
        {$IFDEF VER150}
        tInfo := TypeInfo(TGrammarTokenKind);
        mKind := GetEnumName(tInfo, Ord(PGrammarTokenKind(mLexer^.Parent.CurrentToken.Kind)^));
        {$ELSE}
        {$IFDEF CLASSIC}
        mKind := IntToStr(Ord(PGrammarTokenKind(mLexer^.Parent.CurrentToken.Kind)^));
        {$ELSE}
        mKind := TRttiEnumerationType.GetName(PGrammarTokenKind(mLexer^.Parent.CurrentToken.Kind)^);
        {$ENDIF}
        {$ENDIF}
        {$ENDIF}
      Writeln(Format('token kind = %s: %s @ pos = %d',
        [mKind, mLexer^.Parent.CurrentToken.Value,
        mLexer^.Parent.CurrentToken.StartPos]));
      Continue;
    End;
    Writeln(Format('[ERROR] Illegal token "%s" found at pos %d.',
      [mLexer^.Parent.CurrentToken.Value, mLexer^.Parent.CurrentToken.StartPos]));
  Until TLexer_PeekNextChar(PLexer(mLexer)) = #0;
  mLexer^.Parent.VMT^.Destory(PLexer(mLexer));
  Dispose(mSource);
  Dispose(mLexer);
End;

End.
