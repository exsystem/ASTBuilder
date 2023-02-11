Unit CharRule;

{$I define.inc}

Interface

Uses
  Lexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose(): TLexerRule;

Implementation

Uses
  TypeDef, StringUtils;

// ' ( \ any-but-not-eof | other-than-eof-and-quote ) '
Function Parse(Lexer: PLexer): Boolean;
Var
  mOffset: TSize;
Label
  S1, S2, S3, S4, S5;
Begin
  S1:
    If TLexer_PeekNextChar(Lexer) = '''' Then
    Begin
      TLexer_Forward(Lexer);
      mOffset := 1;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    If TLexer_PeekNextChar(Lexer) = '\' Then
    Begin
      TLexer_Forward(Lexer);
      Inc(mOffset);
      Goto S3;
    End
    Else If (TLexer_PeekNextChar(Lexer) <> #0) And
      (TLexer_PeekNextChar(Lexer) <> '''') Then
    Begin
      TLexer_Forward(Lexer);
      Inc(mOffset);
      Goto S4;
    End
    Else
    Begin
      TLexer_Retract(Lexer, mOffset);
      Result := False;
      Exit;
    End;
  S3:
    If TLexer_PeekNextChar(Lexer) <> #0 Then
    Begin
      TLexer_Forward(Lexer);
      Inc(mOffset);
      Goto S4;
    End
    Else
    Begin
      TLexer_Retract(Lexer, mOffset);
      Result := False;
      Exit;
    End;
  S4:
    If TLexer_PeekNextChar(Lexer) = '''' Then
    Begin
      Lexer.CurrentToken.StartPos := Lexer.NextPos - mOffset;
      TLexer_Forward(Lexer);
      Goto S5;
    End
    Else
    Begin
      TLexer_Retract(Lexer, mOffset);
      Result := False;
      Exit;
    End;
  S5:
    FreeStr(Lexer.CurrentToken.Value);
  Lexer.CurrentToken.Value :=
    SubStr(Lexer.Source, Lexer.CurrentToken.StartPos, Lexer.NextPos -
    Lexer.CurrentToken.StartPos);
  Result := True;
End;

Function Compose(): TLexerRule;
Begin
  Result.TokenKind.TokenKind := eChar;
  Result.TokenKind.TermRule := nil;
  Result.Parser := Parse;
End;

End.
