Unit TermRule;

{$I define.inc}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose: TLexerRule;

Implementation

Uses
  StrUtils;

Function Parse(Lexer: PLexer): Boolean;
Begin
  If Not IsTermIdInitialChar(TLexer_PeekNextChar(Lexer)) Then
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
  Result.TokenKind.TokenKind := eTerm;
  Result.TokenKind.TermRule := nil;
  Result.Parser := Parse;
End;

End.
