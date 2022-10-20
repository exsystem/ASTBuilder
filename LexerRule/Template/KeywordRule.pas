Unit KeywordRule;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer; Keyword: String): Boolean;
Function Compose(Lexer: PLexer; Parser: TLexerRuleParser; TokenKind: TTokenKind;
  Keyword: String): TLexerRule;

Implementation

Uses
  Trie;

Function Parse(Lexer: PLexer; Keyword: String): Boolean;
Begin
  Result := TLexer_PeekNextWord(Lexer, Keyword);
  If Result Then
  Begin
    Lexer.CurrentToken.Value := Keyword;
    Lexer.CurrentToken.StartPos := Lexer.NextPos;
    TLexer_Forward(Lexer, Length(Keyword));
  End;
End;

Function Compose(Lexer: PLexer; Parser: TLexerRuleParser; TokenKind: TTokenKind;
  Keyword: String): TLexerRule;
Begin
  Result.TokenKind := TokenKind;
  Result.Parser := Parser;
  If Keyword <> '' Then
  Begin
    TTrie_Set(Lexer.Keywords, Keyword, @TokenKind);
  End;
End;

End.
