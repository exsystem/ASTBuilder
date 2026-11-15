{ Unit SymbolRule; }
Unit SymbRule;

{$I define.inc}

Interface

Uses
  Lexer, TypeDef;

Function Parse(Lexer: PLexer; Const Ch: AnsiString): Boolean;

Implementation

Uses
  StrUtil;

Function Parse(Lexer: PLexer; Const Ch: AnsiString): Boolean;
Var
  mChar: PTChar;
Begin
  mChar := TLexer_PeekNextChar(Lexer);
  Result := (mChar^.Bytes[0] = Ord(Ch[1]));
  If Result Then
  Begin
    FreeStr(Lexer^.CurrentToken.Value);
    Lexer^.CurrentToken.Value := CreateStr(1);
    PByte(Lexer^.CurrentToken.Value)^ := mChar^.Bytes[0];
    PByte(Lexer^.CurrentToken.Value)[1] := 0;
    Lexer^.CurrentToken.StartPos := TLexer_GetNextPos(Lexer);
    TLexer_Forward(Lexer, 1);
  End;
End;

End.
