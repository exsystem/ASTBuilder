Unit IdRule;

{$I define.inc}

Interface

Uses
  Lexer, GLexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose: TLexerRule;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil, TypeDef;

Function Parse(Lexer: PLexer): Boolean;
Var
  I: TSize;
Begin
  If Not IsNonTermIdInitialChar(TLexer_PeekNextChar(Lexer)) Then
  Begin
    Result := False;
    Exit;
  End;

  Result := True;
  Lexer^.CurrentToken.StartPos := TLexer_GetNextPos(Lexer);
  TLexer_Forward(Lexer, 1);
  I := 1;
  While IsIdChar(TLexer_PeekNextChar(Lexer)) Do
  Begin
    TLexer_Forward(Lexer, 1);
    Inc(I);
  End;
  TLexer_FetchNextToken(Lexer, I);
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := eId;
  Result.Parser := Parse;
End;

End.
