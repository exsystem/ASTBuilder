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
  SysUtils,
  Lexer,
  TestUtil,
 {$IFDEF USE_STRINGS}strings,{$ENDIF} StrUtil;

Procedure Test;
Var
  mSource: PChar;
  mLexer: PLexer;
  mKind: String;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
Begin
  mSource := PropmtForFile('Grammar File Path? (Default = t.xg)', 't.xg');
  mLexer := GetGrammarLexer(mSource);
  Repeat
    If TLexer_GetNextToken(mLexer) Then
    Begin
        {$IFDEF FPC}
        WriteStr(mKind, mLexer.CurrentToken.Kind.TokenKind);
        {$ENDIF}
        {$IFDEF DCC}
        {$IFDEF VER150}
        tInfo := TypeInfo(TGrammarTokenKind);
        mKind := GetEnumName(tInfo, Ord(mLexer^.CurrentToken.Kind.TokenKind));
        {$ENDIF}
        {$IFDEF CLASSIC}
        mKind := IntToStr(Ord(mLexer^.CurrentToken.Kind.TokenKind));
        {$ENDIF}
        {$IFDEF MORDEN}
        mKind := TRttiEnumerationType.GetName(mLexer.CurrentToken.Kind.TokenKind);
        {$ENDIF}
        {$ENDIF}
      Writeln(Format('token kind = %s: %s @ pos = %d',
        [mKind, mLexer^.CurrentToken.Value, mLexer^.CurrentToken.StartPos]));
      Continue;
    End;
    Writeln(Format('[ERROR] Illegal token "%s" found at pos %d.',
      [mLexer^.CurrentToken.Value, mLexer^.CurrentToken.StartPos]));
  Until TLexer_PeekNextChar(mLexer) = #0;
  TLexer_Destroy(mLexer);
  FreeStr(mSource);
End;

End.
