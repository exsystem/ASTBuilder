Unit EofRule;

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer; Out Token: TToken): Boolean;
Function Compose(): TLexerRule;

Implementation

Function Parse(Lexer: PLexer; out Token: TToken): Boolean;
Begin
  If Lexer.CurrentChar = #0 Then
  Begin
    Token.Kind := eEof;
    Token.Value := 'EOF';
    Token.StartPos := Lexer.CurrentPos;
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
