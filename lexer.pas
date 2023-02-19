Unit Lexer;

{$I define.inc}

Interface

Uses
  List, TypeDef, Trie, GrammarNode;

Type
  PTokenKind = ^TTokenKind;

  TGrammarTokenKind = (eUndefined, eUserDefined, eEof, eRoot, eOr,
    eLParen, eRParen, eLBracket, eRBracket, eQuestionMark, ePlus,
    eAsterisk, eColon, eSemi, eId,
    eTerm, eString, eChar, eDoubleDots, eSingleQuote, eTilde, eSkip);

  PToken = ^TToken;

  TTokenKind = Record
    TokenKind: TGrammarTokenKind;
    TermRule: PChar;
  End;

  TToken = Record
    Error: PChar;
    Value: PChar;
    StartPos: TSize;
    Kind: TTokenKind;
  End;

  PLexer = ^TLexer;

  TLexer = Record
    GrammarNode: PGrammarNode;
    Source: PChar;
    NextPos: TSize;
    CurrentToken: TToken;
    Keywords: PTrie; // of <String, TTokenKind>
    RuleList: PList; // of TLexerRule
  End;

  TLexerRuleParser = Function(Lexer: PLexer): Boolean;

  PLexerRule = ^TLexerRule;

  TLexerRule = Record
    TokenKind: TTokenKind;
    Parser: TLexerRuleParser;
  End;

Function TLexer_Create(Const Source: PChar; Const GrammarMode: Boolean = True): PLexer;

Procedure TLexer_Destroy(Var Self: PLexer);

Procedure TLexer_AddRule(Var Self: PLexer; Const Rule: TLexerRule);

Function TLexer_GetNextToken(Var Self: PLexer): Boolean;

Function TLexer_IsToken(Var Self: PLexer; Const TokenKind: TTokenKind): Boolean;

Function TLexer_CompareNextToken(Var Self: PLexer; Const TokenKind: TTokenKind): Boolean;

Procedure TLexer_Forward(Var Self: PLexer; Const Step: TSize = 1);

Function TLexer_PeekNextChar(Var Self: PLexer): Char;

Function TLexer_PeekNextWord(Var Self: PLexer; Const NextWord: PChar): Boolean;

Function TLexer_GetNextChar(Var Self: PLexer): Char;

Procedure TLexer_Retract(Var Self: PLexer; Const Step: TSize = 1);

Implementation

Uses
  SysUtils, StringUtils, NFA, TermRuleNode{$IFDEF USE_STRINGS}, strings{$ENDIF};

Function TLexer_Create(Const Source: PChar; Const GrammarMode: Boolean = True): PLexer;
Begin
  New(Result);
  Result.RuleList := nil;
  If GrammarMode Then
  Begin
    Result.RuleList := TList_Create(SizeOf(TLexerRule), 10);
    Result.Keywords := TTrie_Create(SizeOf(TTokenKind));
  End;
  Result.Source := CreateStr(StrLen(Source) + 1);
  StrCat(Result.Source, Source);
  StrCat(Result.Source, #1);
  Result.NextPos := 0;
  Result.CurrentToken.Value := strnew('');
  Result.CurrentToken.Error := strnew('');
  Result.CurrentToken.Kind.TokenKind := eUndefined;
  Result.CurrentToken.Kind.TermRule := strnew('');
End;

Function TLexer_GetNextToken(Var Self: PLexer): Boolean;
Var
  I: TSize;
  mRule: PLexerRule;
  mKeyword: PTokenKind;
  mTermRuleNode: PTermRuleNode;
  mSavePoint: TSize;
Begin
  If Self.CurrentToken.Kind.TokenKind = eEof Then
  Begin
    Result := False;
    Exit;
  End;
  While IsSpace(TLexer_PeekNextChar(Self)) Do
  Begin
    TLexer_Forward(Self);
  End;

  If Self.RuleList <> nil Then
  Begin
    For I := 0 To Pred(Self.RuleList.Size) Do
    Begin
      mRule := PLexerRule(TList_Get(Self.RuleList, I));
      FreeStr(Self.CurrentToken.Error);
      Self.CurrentToken.Error := strnew('');
      If mRule.Parser(Self) Then
      Begin
        Result := (strcomp(Self.CurrentToken.Error, '') = 0);
        If Result Then
        Begin
          mKeyword := PTokenKind(TTrie_Get(Self.Keywords, Self.CurrentToken.Value));
          If mKeyword <> nil Then
          Begin
            FreeStr(Self.CurrentToken.Kind.TermRule);
            Self.CurrentToken.Kind := mKeyword^;
          End
          Else
          Begin
            FreeStr(Self.CurrentToken.Kind.TermRule);
            Self.CurrentToken.Kind := mRule.TokenKind;
            Self.CurrentToken.Kind.TermRule := strnew(Self.CurrentToken.Kind.TermRule);
          End;
        End
        Else
        Begin
          FreeStr(Self.CurrentToken.Kind.TermRule);
          Self.CurrentToken.Kind.TokenKind := eUndefined;
        End;
        Exit;
      End;
    End;
  End
  Else
  Begin
    For I := 0 To Pred(Self.GrammarNode.TermRules.Size) Do
    Begin
      mTermRuleNode := PPTermRuleNode(TList_Get(Self.GrammarNode.TermRules, I))^;
      FreeStr(Self.CurrentToken.Error);
      Self.CurrentToken.Error := strnew('');
      Result := False;
      If strcomp(mTermRuleNode.Nfa.Keyword, '') <> 0 Then
      Begin
        If Not TLexer_PeekNextWord(Self, mTermRuleNode.Nfa.Keyword) Then
        Begin
          Continue;
        End;
        Self.CurrentToken.Kind.TokenKind := eUserDefined;
        FreeStr(Self.CurrentToken.Kind.TermRule);
        Self.CurrentToken.Kind.TermRule := strnew(mTermRuleNode.Name);
        Self.CurrentToken.StartPos := Self.NextPos;
        FreeStr(Self.CurrentToken.Value);
        Self.CurrentToken.Value := strnew(mTermRuleNode.Nfa.Keyword);
        TLexer_Forward(Self, Length(Self.CurrentToken.Value));
        Result := (strcomp(Self.CurrentToken.Error, '') = 0);
        Exit;
      End
      Else
      Begin
        TNfa_Reset(mTermRuleNode.Nfa);
        Self.CurrentToken.StartPos := Self.NextPos;
        While TNfa_Move(mTermRuleNode.Nfa, TLexer_PeekNextChar(Self)) Do
        Begin
          TLexer_Forward(Self);
          If TNfa_Accepted(mTermRuleNode.Nfa) Then
          Begin
            Result := True;
            mSavePoint := Self.NextPos;
          End;
        End;
        If Result Then
        Begin
          FreeStr(Self.CurrentToken.Value);
          Self.CurrentToken.Value :=
            SubStr(Self.Source, Self.CurrentToken.StartPos, mSavePoint -
            Self.CurrentToken.StartPos);
          Self.CurrentToken.Kind.TokenKind := eUserDefined;
          FreeStr(Self.CurrentToken.Kind.TermRule);
          Self.CurrentToken.Kind.TermRule := strnew(mTermRuleNode.Name);
          Result := (strcomp(Self.CurrentToken.Error, '') = 0);
          TLexer_Retract(Self, mSavePoint - Self.NextPos);
          Exit;
        End;
        Self.CurrentToken.Kind.TokenKind := eUndefined;
      End;
    End;
  End;
  Self.CurrentToken.StartPos := Self.NextPos;
  While (Not IsSpace(TLexer_PeekNextChar(Self))) And (TLexer_PeekNextChar(Self) <> #0) Do
  Begin
    TLexer_Forward(Self);
  End;
  Self.CurrentToken.Kind.TokenKind := eUndefined;
  FreeStr(Self.CurrentToken.Error);
  Self.CurrentToken.Error := strnew('Illegal token.');
  FreeStr(Self.CurrentToken.Value);
  Self.CurrentToken.Value := SubStr(Self.Source, Self.CurrentToken.StartPos,
    Self.NextPos - Self.CurrentToken.StartPos);
  Result := False;
End;

Procedure TLexer_Destroy(Var Self: PLexer);
Var
  I: TSize;
Begin
  If Self.RuleList <> nil Then
  Begin
    TList_Destroy(Self.RuleList);
    TTrie_Destroy(Self.Keywords);
  End;
  FreeStr(Self.CurrentToken.Error);
  FreeStr(Self.CurrentToken.Value);
  FreeStr(Self.CurrentToken.Kind.TermRule);
  FreeStr(Self.Source);
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

Function TLexer_PeekNextWord(Var Self: PLexer; Const NextWord: PChar): Boolean;
Var
  I: TSize;
Begin
  If Self.NextPos + strlen(NextWord) > strlen(Self.Source) Then
  Begin
    Result := False;
    Exit;
  End;
  Result := CompareMem(@Self.Source[Self.NextPos], NextWord,
    strlen(NextWord) * SizeOf(Char));
  If Result Then
  Begin
    Exit;
  End;
  For I := 0 To strlen(NextWord) - 1 Do
  Begin
    If Lower(NextWord[I]) <> Lower(Self.Source[Self.NextPos + I]) Then
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
  If TokenKind.TokenKind = eUserDefined Then
  Begin
    Result := (strcomp(Self.CurrentToken.Kind.TermRule, TokenKind.TermRule) = 0) And
      (Self.CurrentToken.Kind.TokenKind = eUserDefined);
  End
  Else
  Begin
    Result := (Self.CurrentToken.Kind.TokenKind = TokenKind.TokenKind);
  End;
End;

Function TLexer_CompareNextToken(Var Self: PLexer; Const TokenKind: TTokenKind): Boolean;
Begin
  TLexer_GetNextToken(Self);
  Result := TLexer_IsToken(Self, TokenKind);
End;

Procedure TLexer_Retract(Var Self: PLexer; Const Step: TSize = 1);
Begin
  Dec(Self.NextPos, Step);
End;

End.
