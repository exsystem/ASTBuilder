Unit SubRule;

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose(): TLexerRule;

Implementation

Function Parse(Lexer: PLexer): Boolean;
Begin
  If Lexer.CurrentChar = '-' Then
  Begin
    Lexer.CurrentToken.Kind := eSub;
    Lexer.CurrentToken.Value := Lexer.CurrentChar;
    Lexer.CurrentToken.StartPos := Lexer.CurrentPos;
    Exit(True);
  End;
  Exit(False);
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eSub;
  Result.Parser := Parse;
End;

End.
