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
  mAscii: Integer;
  mBytes: Array[0..1] Of Byte;
  mByteSize: TSize;
Begin
  mAscii := TLexer_GetCurrentAsciiChar(Lexer);
  Result := (mAscii = Ord(Ch[1]));
  If Result Then
  Begin
    FreeStr(Lexer^.CurrentToken.Value);
    If TChar_EncodeAscii(Lexer^.FStream^.Encoding, Byte(mAscii),
      @mBytes[0], mByteSize) Then
    Begin
      Lexer^.CurrentToken.Value := CreateStrEncoded(mByteSize,
        Lexer^.FStream^.Encoding);
      Move(mBytes[0], Lexer^.CurrentToken.Value^, mByteSize);
      TChar_SetByteLength(Lexer^.CurrentToken.Value, mByteSize);
    End;
    Lexer^.CurrentToken.StartPos := TLexer_GetNextPos(Lexer);
    TLexer_Forward(Lexer, 1);
  End;
End;

End.
