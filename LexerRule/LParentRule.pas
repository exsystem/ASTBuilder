Unit LParentRule;

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
  Result := (TLexer_PeekNextChar(Lexer) = '(');
  If Result Then
  Begin
    Lexer.CurrentToken.Value := TLexer_PeekNextChar(Lexer); 
    Lexer.CurrentToken.StartPos := Lexer.NextPos;
    TLexer_Forward(Lexer);
  End;
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind := eLParent;
  Result.Parser := Parse;
End;

End.
