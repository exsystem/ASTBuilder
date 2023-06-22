Unit EofRule;

{$I define.inc}

Interface

Uses
  Lexer, GLexer;

Function Parse(Lexer: PLexer): Boolean;

Function Compose: TLexerRule;

Implementation

Uses
  StrUtil, SysUtils;

Function Parse(Lexer: PLexer): Boolean;
Begin
  Result := (TLexer_PeekNextChar(Lexer) = #0);
  If Result Then
  Begin
    FreeStr(Lexer^.CurrentToken.Value);
    Lexer^.CurrentToken.Value := StrNew('');
    Lexer^.CurrentToken.StartPos := TLexer_GetNextPos(Lexer);
    TLexer_Forward(Lexer, 1);
  End;
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := eEof;
  Result.Parser := Parse;
End;

End.
