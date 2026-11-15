{ Unit KeywordRule; }
Unit KywdRule;

{$I define.inc}

Interface

Uses
  Lexer, GLexer, TypeDef;

Function Parse(Lexer: PLexer; Keyword: PTChar): Boolean; Overload;
Function Parse(Lexer: PLexer; Const Keyword: AnsiString): Boolean; Overload;
Function Compose(Lexer: PLexer; Parser: TLexerRuleParser; TokenKind: TGrammarTokenKind;
  Keyword: PTChar): TLexerRule;

Implementation

Uses
  Trie, {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

Function Parse(Lexer: PLexer; Keyword: PTChar): Boolean;
Begin
  Result := TLexer_PeekNextWord(Lexer, Keyword);
  If Result Then
  Begin
    FreeStr(Lexer^.CurrentToken.Value);
    Lexer^.CurrentToken.Value := TCharStrNew(Keyword);
    Lexer^.CurrentToken.StartPos := TLexer_GetNextPos(Lexer);
    TLexer_Forward(Lexer, Lexer^.FLastPeekCharCount);
  End;
End;

Function Parse(Lexer: PLexer; Const Keyword: AnsiString): Boolean;
Var
  mKeyword: PTChar;
Begin
  mKeyword := TCharStrNew(Keyword);
  Result := Parse(Lexer, mKeyword);
  FreeStr(mKeyword);
End;

Function Compose(Lexer: PLexer; Parser: TLexerRuleParser; TokenKind: TGrammarTokenKind;
  Keyword: PTChar): TLexerRule;
Begin
  Result.TokenKind := TokenKind;
  Result.Parser := Parser;
  If TCharStrComp(Keyword, '') <> 0 Then
  Begin
    TTrie_Set(PGrammarLexer(Lexer)^.Keywords, Keyword, @TokenKind);
  End;
End;

End.
