{ Unit StringRule; }
Unit StrRule;

{$I define.inc}

Interface

Uses
  Lexer, GLexer;

Function Parse(Lexer: PLexer): Boolean;
Function Compose: TLexerRule;

Implementation

Uses
  TypeDef;

{ ' ( other-than-eof-and-quote | \ any-but-not-eof ) * '     }
{ first make a NFA for this regexp, then transform into DFA. }
Function Parse(Lexer: PLexer): Boolean;
Var
  mOffset: TSize;
Label
  S1, S2, S3, S4;
Begin
  S1:
    If TLexer_PeekNextChar(Lexer) = '''' Then
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
    If TLexer_PeekNextChar(Lexer) = '''' Then
    Begin
      Lexer^.CurrentToken.StartPos := TLexer_GetNextPos(Lexer) - mOffset;
      TLexer_Forward(Lexer, 1);
      { Inc(mOffset); }
      Goto S4;
    End
    Else If TLexer_PeekNextChar(Lexer) = '\' Then
    Begin
      TLexer_Forward(Lexer, 1);
      Inc(mOffset);
      Goto S3;
    End
    Else If TLexer_PeekNextChar(Lexer) <> #0 Then
    Begin
      TLexer_Forward(Lexer, 1);
      Inc(mOffset);
      Goto S2;
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
      TLexer_Forward(Lexer, 1);
      Inc(mOffset);
      Goto S2;
    End
    Else
    Begin
      TLexer_Retract(Lexer, mOffset);
      Result := False;
      Exit;
    End;
  S4:
    Result := True;
  TLexer_FetchNextToken(Lexer, TLexer_GetNextPos(Lexer) - Lexer^.CurrentToken.StartPos);
End;

Function Compose: TLexerRule;
Begin
  Result.TokenKind := eString;
  Result.Parser := Parse;
End;

End.
