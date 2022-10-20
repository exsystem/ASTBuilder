Unit IdRule;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose(): TLexerRule;

Implementation

Uses
  StringUtils;

Function Parse(Lexer: PLexer): Boolean;
Begin
  If Not IsIdInitialChar(TLexer_PeekNextChar(Lexer)) Then
  Begin
    Result := False;
    Exit;
  End;

  Result := True;
  Lexer.CurrentToken.StartPos := Lexer.NextPos;
  TLexer_Forward(Lexer);
  While IsIdChar(TLexer_PeekNextChar(Lexer)) Do
  Begin
    TLexer_Forward(Lexer);
  End;

  Lexer.CurrentToken.Value :=
    Copy(Lexer.Source, Lexer.CurrentToken.StartPos, Lexer.NextPos -
    Lexer.CurrentToken.StartPos);
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eId;
  Result.Parser := Parse;
End;

End.
