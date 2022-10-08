Unit DivRule;

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
  Result := (Lexer.CurrentChar = '/');
  If Result Then
  Begin
    Lexer.CurrentToken.Kind := eDiv;
    Lexer.CurrentToken.Value := Lexer.CurrentChar;
    Lexer.CurrentToken.StartPos := Lexer.CurrentPos;
  End;
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eDiv;
  Result.Parser := Parse;
End;

End.
