{ Unit IndividualCharFactorRuleUnit; }
Unit ICFRUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, NFA;

Function IndividualCharFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function IndividualCharFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Function IndividualCharFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;

Function IndividualCharFactorRuleExpression3(Parser: PParser; Var Nfa: PNfa): Boolean;

Function IndividualCharFactorRuleExpression4(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TrmNode, GrpNode,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil, GLEXER, GPARSER;

Function DecodeCharLiteral(Value: PTChar; Bytes: PByte; Out ByteSize: TSize;
  Out AsciiValue: Byte; Out IsAscii: Boolean): Boolean;
Var
  I, mEnd, mCharSize: TSize;
  mEncoding: TEncodingKind;
  mAscii: Byte;
Begin
  Result := False;
  ByteSize := 0;
  IsAscii := False;
  If Value = nil Then
    Exit;
  mEncoding := TChar_GetEncoding(Value);
  mEnd := TCharStrByteOffset(Value, TCharStrLen(Value) - 1);
  I := TCharStrByteOffset(Value, 1);
  If (I >= mEnd) Or Not TChar_GetEncodedSize(mEncoding,
    @PByte(Value)[I], mEnd - I, mCharSize) Then
    Exit;
  If TChar_GetAsciiValue(mEncoding, @PByte(Value)[I], mCharSize, mAscii) And
    (mAscii = Ord('\')) Then
  Begin
    Inc(I, mCharSize);
    If (I >= mEnd) Or Not TChar_GetEncodedSize(mEncoding,
      @PByte(Value)[I], mEnd - I, mCharSize) Then
      Exit;
    If TChar_GetAsciiValue(mEncoding, @PByte(Value)[I], mCharSize, mAscii) Then
    Begin
      mAscii := EscapeChar(mAscii);
      If Not TChar_EncodeAscii(mEncoding, mAscii, Bytes, ByteSize) Then
        Exit;
    End
    Else
    Begin
      Move(PByte(Value)[I], Bytes^, mCharSize);
      ByteSize := mCharSize;
    End;
  End
  Else
  Begin
    Move(PByte(Value)[I], Bytes^, mCharSize);
    ByteSize := mCharSize;
  End;
  IsAscii := TChar_GetAsciiValue(mEncoding, Bytes, ByteSize, AsciiValue);
  Result := True;
End;

{ individualCharFactor -> TChar DoubleDots TChar }
Function IndividualCharFactorRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mSavePointS1: TSize;
  mFrom, mTo: PTChar;
  mFromBytes, mToBytes, mChBytes: Array[0..3] Of Byte;
  mFromSize, mToSize, mChSize: TSize;
  mFromAscii, mToAscii, mCh: Byte;
  mFromIsAscii, mToIsAscii: Boolean;
  mEncoding: TEncodingKind;
Label
  S1, S2, S3, S4;
Begin
  S1:
    mSavePointS1 := Parser^.FCurrentToken;
  If TGrammarParser_Term(Parser, eChar) Then
  Begin
    mFrom := TCharStrNew(TParser_GetCurrentToken(Parser)^.Value);
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  S2:
    If TGrammarParser_Term(Parser, eDoubleDots) Then
    Begin
    End
    Else
    Begin
      FreeStr(mFrom);
      Parser^.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S3:
    If TGrammarParser_Term(Parser, eChar) Then
    Begin
      mTo := TCharStrNew(TParser_GetCurrentToken(Parser)^.Value);
    End
    Else
    Begin
      FreeStr(mFrom);
      Parser^.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S4:
    If Not DecodeCharLiteral(mFrom, @mFromBytes[0], mFromSize,
      mFromAscii, mFromIsAscii) Or
      Not DecodeCharLiteral(mTo, @mToBytes[0], mToSize,
      mToAscii, mToIsAscii) Or Not mFromIsAscii Or Not mToIsAscii Then
    Begin
      FreeStr(mFrom);
      FreeStr(mTo);
      Parser^.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  mEncoding := TChar_GetEncoding(mFrom);
  TNfa_Create(Nfa);
  If mToAscii < mFromAscii Then
  Begin
    TNfa_Destroy(Nfa);
    FreeStr(mFrom);
    FreeStr(mTo);
    Parser^.FCurrentToken := mSavePointS1;
    Result := False;
    Exit;
  End;
  For mCh := mFromAscii To mToAscii Do
  Begin
    If TChar_EncodeAscii(mEncoding, mCh, @mChBytes[0], mChSize) Then
      TNfa_AddEdgeSized(Nfa, PTChar(@mChBytes[0]), mChSize, mEncoding, 0, 1);
  End;
  FreeStr(mFrom);
  FreeStr(mTo);
  TNfa_GetState(Nfa, 1)^.Acceptable := True;
  Result := True;
End;

{ individualCharFactor -> TChar }
Function IndividualCharFactorRuleExpression2(Parser: PParser; Var Nfa: PNfa): Boolean;
Label
  S1, S2;
Var
  mValue: PTChar;
  mBytes: Array[0..3] Of Byte;
  mByteSize: TSize;
  mAscii: Byte;
  mIsAscii: Boolean;
Begin
  S1:
    If TGrammarParser_Term(Parser, eChar) Then
    Begin
      { NOP }
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    mValue := TParser_GetCurrentToken(Parser)^.Value;
  If Not DecodeCharLiteral(mValue, @mBytes[0], mByteSize,
    mAscii, mIsAscii) Then
  Begin
    Result := False;
    Exit;
  End;
  TNfa_Create(Nfa);
  TNfa_AddEdgeSized(Nfa, PTChar(@mBytes[0]), mByteSize,
    TChar_GetEncoding(mValue), 0, 1);
  TNfa_GetState(Nfa, 1)^.Acceptable := True;
  Result := True;
End;

{ TODO individualCharFactor -> CharSet ; [a-z\n\r] }
Function IndividualCharFactorRuleExpression3(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mTerm: PTChar;
  mEncoding: TEncodingKind;
  mI, mEndByte, mAfterCurrent, mAfterNext, mAfterEnd: TSize;
  mCurrent, mNext, mLast, mEncoded: Array[0..3] Of Byte;
  mCurrentSize, mNextSize, mLastSize, mEncodedSize: TSize;
  mCurrentAscii, mNextAscii, mLastAscii, mCode: Byte;
  mCurrentIsAscii, mNextIsAscii, mLastIsAscii, mHasNext: Boolean;
  mNextEscaped, mIgnoredEscaped: Boolean;
  Function ReadSetChar(Var Offset: TSize; Bytes: PByte;
    Var ByteSize: TSize; Var AsciiValue: Byte;
    Var IsAscii, IsEscaped: Boolean): Boolean;
  Var
    mCharSize: TSize;
    mValue: Byte;
  Begin
    Result := False;
    IsAscii := False;
    IsEscaped := False;
    ByteSize := 0;
    If (Offset >= mEndByte) Or Not TChar_GetEncodedSize(mEncoding,
      @PByte(mTerm)[Offset], mEndByte - Offset, mCharSize) Then
      Exit;
    If TChar_GetAsciiValue(mEncoding, @PByte(mTerm)[Offset], mCharSize,
      mValue) And (mValue = Ord('\')) Then
    Begin
      IsEscaped := True;
      Inc(Offset, mCharSize);
      If (Offset >= mEndByte) Or Not TChar_GetEncodedSize(mEncoding,
        @PByte(mTerm)[Offset], mEndByte - Offset, mCharSize) Then
        Exit;
      If TChar_GetAsciiValue(mEncoding, @PByte(mTerm)[Offset], mCharSize,
        mValue) Then
      Begin
        mValue := EscapeChar(mValue);
        Result := TChar_EncodeAscii(mEncoding, mValue, Bytes, ByteSize);
        If Result Then
        Begin
          AsciiValue := mValue;
          IsAscii := True;
        End;
      End
      Else
      Begin
        Move(PByte(mTerm)[Offset], Bytes^, mCharSize);
        ByteSize := mCharSize;
        IsAscii := TChar_GetAsciiValue(mEncoding, Bytes, ByteSize, AsciiValue);
        Result := True;
      End;
      Inc(Offset, mCharSize);
    End
    Else
    Begin
      Move(PByte(mTerm)[Offset], Bytes^, mCharSize);
      ByteSize := mCharSize;
      IsAscii := TChar_GetAsciiValue(mEncoding, Bytes, ByteSize, AsciiValue);
      Inc(Offset, mCharSize);
      Result := True;
    End;
  End;
Begin
  If Not TGrammarParser_Term(Parser, eCharSet) Then
  Begin
    Result := False;
    Exit;
  End;
  mTerm := TParser_GetCurrentToken(Parser)^.Value;
  mEncoding := TChar_GetEncoding(mTerm);
  mEndByte := TCharStrByteOffset(mTerm, TCharStrLen(mTerm) - 1);
  mI := TCharStrByteOffset(mTerm, 1);
  TNfa_Create(Nfa);
  Result := True;
  While mI < mEndByte Do
  Begin
    mAfterCurrent := mI;
    If Not ReadSetChar(mAfterCurrent, @mCurrent[0], mCurrentSize,
      mCurrentAscii, mCurrentIsAscii, mIgnoredEscaped) Then
    Begin
      Result := False;
      Break;
    End;
    mAfterNext := mAfterCurrent;
    mHasNext := ReadSetChar(mAfterNext, @mNext[0], mNextSize,
      mNextAscii, mNextIsAscii, mNextEscaped);
    If mHasNext And Not mNextEscaped And mNextIsAscii And
      (mNextAscii = Ord('-')) Then
    Begin
      mAfterEnd := mAfterNext;
      If ReadSetChar(mAfterEnd, @mLast[0], mLastSize,
        mLastAscii, mLastIsAscii, mIgnoredEscaped) Then
      Begin
        If mCurrentIsAscii And mLastIsAscii And
          (mLastAscii >= mCurrentAscii) Then
        Begin
          For mCode := mCurrentAscii To mLastAscii Do
          Begin
            If TChar_EncodeAscii(mEncoding, mCode, @mEncoded[0], mEncodedSize) Then
              TNfa_AddEdgeSized(Nfa, PTChar(@mEncoded[0]), mEncodedSize,
                mEncoding, 0, 1);
          End;
        End
        Else
        Begin
          TNfa_AddEdgeSized(Nfa, PTChar(@mCurrent[0]), mCurrentSize,
            mEncoding, 0, 1);
          TNfa_AddEdgeSized(Nfa, PTChar(@mNext[0]), mNextSize,
            mEncoding, 0, 1);
          TNfa_AddEdgeSized(Nfa, PTChar(@mLast[0]), mLastSize,
            mEncoding, 0, 1);
        End;
        mI := mAfterEnd;
        Continue;
      End;
    End;
    TNfa_AddEdgeSized(Nfa, PTChar(@mCurrent[0]), mCurrentSize,
      mEncoding, 0, 1);
    mI := mAfterCurrent;
  End;
  If Not Result Then
  Begin
    TNfa_Destroy(Nfa);
    Exit;
  End;
  TNfa_GetState(Nfa, 1)^.Acceptable := True;
End;

{ individualCharFactor -> Dot ; }
Function IndividualCharFactorRuleExpression4(Parser: PParser; Var Nfa: PNfa): Boolean;
Label
  S1, S2;
Begin
  S1:
    If TGrammarParser_Term(Parser, eDot) Then
    Begin
      { NOP }
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    TNfa_Create(Nfa);
  TNfa_AnyChar(Nfa, 0, 1);
  TNfa_GetState(Nfa, 1)^.Acceptable := True;
  Result := True;
End;

Function IndividualCharFactorRule(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := IndividualCharFactorRuleExpression1(Parser, Nfa) Or
    IndividualCharFactorRuleExpression2(Parser, Nfa) Or
    IndividualCharFactorRuleExpression3(Parser, Nfa) Or
    IndividualCharFactorRuleExpression4(Parser, Nfa);
End;

End.
