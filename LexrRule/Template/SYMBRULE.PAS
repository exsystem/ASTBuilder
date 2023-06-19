{ Unit SymbolRule; }
Unit SymbRule;

{$I define.inc}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer; Const Ch: Char): Boolean;

Implementation

Uses
  StrUtil;

Function Parse(Lexer: PLexer; Const Ch: Char): Boolean;
Begin
  Result := (TLexer_PeekNextChar(Lexer) = Ch);
  If Result Then
  Begin
    FreeStr(Lexer^.CurrentToken.Value);
    Lexer^.CurrentToken.Value := CreateStr(1);
    Lexer^.CurrentToken.Value[0] := TLexer_PeekNextChar(Lexer);
    Lexer^.CurrentToken.Value[1] := #0;
    Lexer^.CurrentToken.StartPos := TLexer_GetNextPos(Lexer);
    TLexer_Forward(Lexer, 1);
  End;
End;

End.
