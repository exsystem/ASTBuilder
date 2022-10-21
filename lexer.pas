Unit Lexer;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  List, TypeDef, Trie;

Type
  PTokenKind = ^TTokenKind;
  TTokenKind = (eUndefined, eNot, eAnd, eOr, eXor, ePlus, eMinus, eMul,
    eSlash, eDiv, eMod, eShl, eShr, eEqual, eNotEqual, eLT, eLE, eGT, eGE,
    eLParent, eRParent, eAs, eIs, eIn, eAt, ePointer, eNum, eId, eColon,
    eLBrack, eRBrack, eLBrack2, eRBrack2, eComma, eDot, eAssign, eEof);
  PToken = ^TToken;

  TToken = Record
    Kind: TTokenKind;
    Error: String;
    Value: String;
    StartPos: TSize;
  End;
  PLexer = ^TLexer;

  TLexer = Record
    RuleList: PList;
    Keywords: PTrie; // of <String, TTokenKind>  
    Source: String;
    NextPos: TSize;
    CurrentToken: TToken;
  End;
  TLexerRuleParser = Function(Lexer: PLexer): Boolean;
  PLexerRule = ^TLexerRule;

  TLexerRule = Record
    TokenKind: TTokenKind;
    Parser: TLexerRuleParser;
  End;

Function TLexer_Create(Const Source: String): PLexer;
Procedure TLexer_Destroy(Var Self: PLexer);
Procedure TLexer_AddRule(Var Self: PLexer; Const Rule: TLexerRule);
Function TLexer_GetNextToken(Var Self: PLexer): Boolean;
Function TLexer_IsToken(Var Self: PLexer; Const TokenKind: TTokenKind): Boolean;
Function TLexer_CompareNextToken(Var Self: PLexer;
  Const TokenKind: TTokenKind): Boolean;
Procedure TLexer_Forward(Var Self: PLexer; Const Step: TSize = 1);
Function TLexer_PeekNextChar(Var Self: PLexer): Char;
Function TLexer_PeekNextWord(Var Self: PLexer; Const NextWord: String): Boolean;
Function TLexer_GetNextChar(Var Self: PLexer): Char;
Procedure TLexer_Retract(Var Self: PLexer);

Implementation

Uses
  StringUtils, SysUtils;

Function TLexer_Create(Const Source: String): PLexer;
Begin
  New(Result);
  Result.RuleList := TList_Create(SizeOf(TLexerRule), 10);
  Result.Keywords := TTrie_Create(SizeOf(TTokenKind));
  Result.Source := Source + #0;
  Result.NextPos := 1;
  Result.CurrentToken.Kind := eUndefined;
End;

Function TLexer_GetNextToken(Var Self: PLexer): Boolean;
Var
  I: TSize;
  mRule: PLexerRule;
  mKeyword: PTokenKind;
Begin
  If Self.CurrentToken.Kind = eEof Then
  Begin
    Result := False;
    Exit;
  End;
  While IsSpace(TLexer_PeekNextChar(Self)) Do
  Begin
    TLexer_Forward(Self);
  End;
  For I := 0 To Pred(Self.RuleList.Size) Do
  Begin
    mRule := PLexerRule(TList_Get(Self.RuleList, I));
    Self.CurrentToken.Error := '';
    If mRule.Parser(Self) Then
    Begin
      Result := (Self.CurrentToken.Error = '');
      If Result Then
      Begin
        mKeyword := PTokenKind(TTrie_Get(Self.Keywords, Self.CurrentToken.Value));
        If mKeyword <> nil Then
        Begin
          Self.CurrentToken.Kind := mKeyword^;
        End
        Else
        Begin
          Self.CurrentToken.Kind := mRule.TokenKind;
        End;
      End
      Else
      Begin
        Self.CurrentToken.Kind := eUndefined;
      End;
      Exit;
    End;
  End;
  Self.CurrentToken.StartPos := Self.NextPos;
  While (Not IsSpace(TLexer_PeekNextChar(Self))) And
    (TLexer_PeekNextChar(Self) <> #0) Do
  Begin
    TLexer_Forward(Self);
  End;
  Self.CurrentToken.Kind := eUndefined;
  Self.CurrentToken.Error := 'Illegal token.';
  Self.CurrentToken.Value := Copy(Self.Source, Self.CurrentToken.StartPos,
    Self.NextPos - Self.CurrentToken.StartPos);
  Result := False;
End;

Procedure TLexer_Destroy(Var Self: PLexer);
Begin
  Dispose(Self.RuleList);
  Dispose(Self.Keywords);
  Dispose(Self);
  Self := nil;
End;

Procedure TLexer_Forward(Var Self: PLexer; Const Step: TSize = 1);
Begin
  Inc(Self.NextPos, Step);
End;

Function TLexer_PeekNextChar(Var Self: PLexer): Char;
Begin
  Result := Self.Source[Self.NextPos];
End;

Function TLexer_GetNextChar(Var Self: PLexer): Char;
Begin
  Result := TLexer_PeekNextChar(Self);
  TLexer_Forward(Self);
End;

Function TLexer_PeekNextWord(Var Self: PLexer; Const NextWord: String): Boolean;
Var
  I: TSize;
Begin
  If Self.NextPos + Length(NextWord) > Length(Self.Source) Then
  Begin
    Result := False;
    Exit;
  End;
  Result := CompareMem(@Self.Source[Self.NextPos], @NextWord[1],
    Length(NextWord) * SizeOf(Char));
  If Result Then
  Begin
    Exit;
  End;
  For I := Low(NextWord) To High(NextWord) Do
  Begin
    If Lower(NextWord[I]) <> Lower(Self.Source[Self.NextPos + I - Low(NextWord)]) Then
    Begin
      Result := False;
      Exit;
    End;
  End;
  Result := True;
End;

Procedure TLexer_AddRule(Var Self: PLexer; Const Rule: TLexerRule);
Begin
  TList_PushBack(Self.RuleList, @Rule);
End;

Function TLexer_IsToken(Var Self: PLexer; Const TokenKind: TTokenKind): Boolean;
Begin
  Result := (Self.CurrentToken.Kind = TokenKind);
End;

Function TLexer_CompareNextToken(Var Self: PLexer;
  Const TokenKind: TTokenKind): Boolean;
Begin
  TLexer_GetNextToken(Self);
  Result := TLexer_IsToken(Self, TokenKind);
End;

Procedure TLexer_Retract(Var Self: PLexer);
Begin
  Dec(Self.NextPos);
End;

End.
