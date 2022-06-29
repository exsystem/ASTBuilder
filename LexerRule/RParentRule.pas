Unit RParentRule;

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer; Out Token: TToken): Boolean;
Function Compose(): TLexerRule;

Implementation

Function Parse(Lexer: PLexer; out Token: TToken): Boolean;
Begin
  If Lexer.CurrentChar = ')' Then
  Begin
    Token.Kind := eRParent;
    Token.Value := Lexer.CurrentChar;
    Token.StartPos := Lexer.CurrentPos;
    Exit(True);
  End;
  Exit(False);
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eRParent;
  Result.Parser := Parse;
End;

End.
