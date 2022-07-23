Unit DivRule;

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose(): TLexerRule;

Implementation

Function Parse(Lexer: PLexer): Boolean;
Begin
  If Lexer.CurrentChar = '/' Then
  Begin
    Lexer.CurrentToken.Kind := eDiv;
    Lexer.CurrentToken.Value := Lexer.CurrentChar;
    Lexer.CurrentToken.StartPos := Lexer.CurrentPos;
    Exit(True);
  End;
  Exit(False);
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eDiv;
  Result.Parser := Parse;
End;

End.
