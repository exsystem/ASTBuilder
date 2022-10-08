Unit EofRule;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose(): TLexerRule;

Implementation

Function Parse(Lexer: PLexer): Boolean;
Begin
  Result := (Lexer.CurrentChar = #0);
  If Result Then
  Begin
    Lexer.CurrentToken.Kind := eEof;
    Lexer.CurrentToken.Value := 'EOF';
    Lexer.CurrentToken.StartPos := Lexer.CurrentPos;
  End;
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eEof;
  Result.Parser := Parse;
End;

End.
