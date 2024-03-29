{ Unit CharSetRule; }
Unit ChStRule;

{$I define.inc}

Interface

Uses
  Lexer, GLexer;

Function Parse(Lexer: PLexer): Boolean;

Function Compose: TLexerRule;

Implementation

Uses
  TypeDef;

Function Parse(Lexer: PLexer): Boolean;
Var
  mOffset: TSize;
  mCurr: Char;
Label
  S1, S2, S3;
Begin
  S1:
    If TLexer_PeekNextChar(Lexer) = '[' Then
    Begin
      TLexer_Forward(Lexer, 1);
      mOffset := 1;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    mCurr := TLexer_PeekNextChar(Lexer);
  If mCurr = #0 Then
  Begin
    TLexer_Retract(Lexer, mOffset);
    Result := False;
    Exit;
  End;
  If mCurr = '\' Then
  Begin
    TLexer_Forward(Lexer, 2);
    Inc(mOffset, 2);
    Goto S2;
  End
  Else
  If mCurr = '[' Then
  Begin
    TLexer_Retract(Lexer, mOffset);
    Result := False;
    Exit;
  End
  Else If mCurr = ']' Then
  Begin
    TLexer_Forward(Lexer, 1);
    Inc(mOffset);
    Goto S3;
  End
  Else
  Begin
    TLexer_Forward(Lexer, 1);
    Inc(mOffset);
    Goto S2;
  End;
  S3:
  Lexer^.CurrentToken.StartPos := TLexer_GetNextPos(Lexer) - mOffset;
  TLexer_FetchNextToken(Lexer, TLexer_GetNextPos(Lexer) - Lexer^.CurrentToken.StartPos);
  Result := True;
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := eCharSet;
  Result.Parser := Parse;
End;

End.
