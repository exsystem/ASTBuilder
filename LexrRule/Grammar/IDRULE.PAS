Unit IdRule;

{$I define.inc}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose: TLexerRule;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

Function Parse(Lexer: PLexer): Boolean;
Begin
  If Not IsNonTermIdInitialChar(TLexer_PeekNextChar(Lexer)) Then
  Begin
    Result := False;
    Exit;
  End;

  Result := True;
  Lexer^.CurrentToken.StartPos := Lexer^.NextPos;
  TLexer_Forward(Lexer, 1);
  While IsIdChar(TLexer_PeekNextChar(Lexer)) Do
  Begin
    TLexer_Forward(Lexer, 1);
  End;

  FreeStr(Lexer^.CurrentToken.Value);
  Lexer^.CurrentToken.Value :=
    SubStr(Lexer^.Source, Lexer^.CurrentToken.StartPos, Lexer^.NextPos -
    Lexer^.CurrentToken.StartPos);
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind.TokenKind := eId;
  Result.TokenKind.TermRule := nil;
  Result.Parser := Parse;
End;

End.
