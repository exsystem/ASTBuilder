Unit NumRule;

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer; Out Token: TToken): Boolean;
Function Compose(): TLexerRule;

Implementation

Uses
  StringUtils;

Function Parse(Lexer: PLexer; out Token: TToken): Boolean;
Begin
  If IsDigit(Lexer.CurrentChar) Then
  Begin
    // look self...
    Token.StartPos := Lexer.CurrentPos;
    While IsDigit(TLexer_PeekNextChar(Lexer)) Do
    Begin
      TLexer_MoveNextChar(Lexer);
    End;
    // look after...
    If Not (TLexer_PeekNextChar(Lexer) In [' ', '+', '-', '*', '/', ')']) Then
    Begin
      Token.Kind := eUndefined;
      TLexer_MoveNextChar(Lexer);
      While (Not IsSpace(TLexer_PeekNextChar(Lexer))) And
        (TLexer_PeekNextChar(Lexer) <> #0) Do
      Begin
        TLexer_MoveNextChar(Lexer);
      End;
      Token.Value := Copy(Lexer.Source, Token.StartPos, Lexer.CurrentPos -
        Token.StartPos + 1);
      Exit(False);
    End;
    Token.Kind := eNum;
    Token.Value := Copy(Lexer.Source, Token.StartPos, Lexer.CurrentPos -
      Token.StartPos + 1);
    Exit(True);
  End;
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eNum;
  Result.Parser := Parse;
End;

End.
