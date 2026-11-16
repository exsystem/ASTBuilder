Unit TermRule;

{$I define.inc}

Interface

Uses
  Lexer, GLexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose: TLexerRule;

Implementation

Uses
  StrUtil, TypeDef;

Function Parse(Lexer: PLexer): Boolean;
Var
  I: TSize;
  mAscii: Integer;
Begin
  mAscii := TLexer_GetCurrentAsciiChar(Lexer);
  If (mAscii < 0) Or Not IsTermIdInitialChar(Byte(mAscii)) Then
  Begin
    Result := False;
    Exit;
  End;

  Result := True;
  Lexer^.CurrentToken.StartPos := TLexer_GetNextPos(Lexer);
  TLexer_Forward(Lexer, 1);
  I := 1;
  While True Do
  Begin
    mAscii := TLexer_GetCurrentAsciiChar(Lexer);
    If (mAscii < 0) Or Not IsIdChar(Byte(mAscii)) Then
      Break;
    TLexer_Forward(Lexer, 1);
    Inc(I);
  End;
  TLexer_FetchNextToken(Lexer, I);
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := eTerm;
  Result.Parser := Parse;
End;

End.
