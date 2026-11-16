{ Unit StringFactorRuleUnit; }
Unit SFRUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, NFA;

Function StringFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function StringFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Function StringFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TrmNode, GrpNode, ChFRUnit,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil, GLEXER, GPARSER;

{ stringFactor -> charFactor }
Function StringFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := CharFactorRule(Parser, Nfa);
End;

{ stringFactor -> string }
Function StringFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mToken: PToken;
  I, J, mEndByte, mCharSize, mNextCharSize: TSize;
  mEncoding: TEncodingKind;
  mAscii, mEscapedChar: Byte;
  mEscapedBytes: Array[0..3] Of Byte;
Label
  S1, S2;
Begin
  S1:
    If TGrammarParser_Term(Parser, eString) Then
    Begin
      TNfa_Create(Nfa);
      mToken := TParser_GetCurrentToken(Parser);
      mEncoding := TChar_GetEncoding(mToken^.Value);
      mEndByte := TCharStrByteOffset(mToken^.Value,
        TCharStrLen(mToken^.Value) - 1);
      I := TCharStrByteOffset(mToken^.Value, 1);
      J := 0;
      While I < mEndByte Do
      Begin
        If Not TChar_GetEncodedSize(mEncoding, @PByte(mToken^.Value)[I],
          mEndByte - I, mCharSize) Then
          mCharSize := 1;
        If TChar_GetAsciiValue(mEncoding, @PByte(mToken^.Value)[I],
          mCharSize, mAscii) And (mAscii = Ord('\')) Then
        Begin
          Inc(I, mCharSize);
          If I < mEndByte Then
          Begin
            If Not TChar_GetEncodedSize(mEncoding, @PByte(mToken^.Value)[I],
              mEndByte - I, mNextCharSize) Then
              mNextCharSize := 1;
            If TChar_GetAsciiValue(mEncoding, @PByte(mToken^.Value)[I],
              mNextCharSize, mAscii) Then
            Begin
              mEscapedChar := EscapeChar(mAscii);
              If TChar_EncodeAscii(mEncoding, mEscapedChar,
                @mEscapedBytes[0], mNextCharSize) Then
                TNfa_AddEdgeSized(Nfa, PTChar(@mEscapedBytes[0]),
                  mNextCharSize, mEncoding, J, J + 1);
            End
            Else
              TNfa_AddEdgeSized(Nfa, PTChar(@PByte(mToken^.Value)[I]),
                mNextCharSize, mEncoding, J, J + 1);
            Inc(J);
            Inc(I, mNextCharSize);
          End;
        End
        Else
        Begin
          TNfa_AddEdgeSized(Nfa, PTChar(@PByte(mToken^.Value)[I]),
            mCharSize, mEncoding, J, J + 1);
          Inc(J);
          Inc(I, mCharSize);
        End;
      End;
      TNfa_GetState(Nfa, Nfa^.States^.Size - 1)^.Acceptable := True;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    Result := True;
End;

Function StringFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := StringFactorRuleExpression1(Parser, Nfa) Or
    StringFactorRuleExpression2(Parser, Nfa);
End;

End.
