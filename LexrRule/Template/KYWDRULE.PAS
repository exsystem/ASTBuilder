{ Unit KeywordRule; }
Unit KywdRule;

{$I define.inc}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer; Keyword: PChar): Boolean;
Function Compose(Lexer: PLexer; Parser: TLexerRuleParser; TokenKind: TTokenKind;
  Keyword: PChar): TLexerRule;

Implementation

Uses
  Trie, {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

Function Parse(Lexer: PLexer; Keyword: PChar): Boolean;
Begin
  Result := TLexer_PeekNextWord(Lexer, Keyword);
  If Result Then
  Begin
    FreeStr(Lexer^.CurrentToken.Value);
    Lexer^.CurrentToken.Value := strnew(Keyword);
    Lexer^.CurrentToken.StartPos := Lexer^.NextPos;
    TLexer_Forward(Lexer, StrLen(Keyword));
  End;
End;

Function Compose(Lexer: PLexer; Parser: TLexerRuleParser; TokenKind: TTokenKind;
  Keyword: PChar): TLexerRule;
Begin
  Result.TokenKind := TokenKind;
  Result.Parser := Parser;
  If StrComp(Keyword, '') <> 0 Then
  Begin
    TTrie_Set(Lexer^.Keywords, Keyword, @TokenKind);
  End;
End;

End.
