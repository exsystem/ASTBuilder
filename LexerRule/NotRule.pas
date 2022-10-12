Unit NotRule;

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
Const
  CToken: String = 'Not';
Begin
  Result := TLexer_PeekNextWord(Lexer, CToken) {And
    (TLexer_PeekNextChar(Lexer) In [' ', '('])};
  If Result Then
  Begin
    Lexer.CurrentToken.Value := CToken;
    Lexer.CurrentToken.StartPos := Lexer.NextPos;
    TLexer_Forward(Lexer, Length(CToken));
  End;
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eNot;
  Result.Parser := Parse;
End;

End.
