Unit EofRule;

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose(): TLexerRule;

Implementation

Function Parse(Lexer: PLexer): Boolean;
Begin
  If Lexer.CurrentChar = #0 Then
  Begin
    Lexer.CurrentToken.Kind := eEof;
    Lexer.CurrentToken.Value := 'EOF';
    Lexer.CurrentToken.StartPos := Lexer.CurrentPos;
    Exit(True);
  End;
  Exit(False);
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eEof;
  Result.Parser := Parse;
End;

End.
