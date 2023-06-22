{ Unit GrammarLexer; }
Unit GLexer;

{$I define.inc}

Interface

Uses
  List, TypeDef, Trie, Stream, Lexer;

Type
  PGrammarTokenKind = ^TGrammarTokenKind;

  TGrammarTokenKind = (eUndefined, eUserDefined, eEof, eRoot, eOr,
    eLParen, eRParen, eLBracket, eRBracket, eLCurlyBracket, eRCurlyBracket,
    eQuestionMark, ePlus,
    eAsterisk, eColon, eEqual, eSemi, eId,
    eTerm, eString, eChar, eCharSet, eDot, eDoubleDots, eSingleQuote,
    eTilde, eSkip, eOptions);

  PGrammarLexer = ^TGrammarLexer;

  TGrammarLexer = Record
    Parent: TLexer;
    RuleList: PList; { of TLexerRule }
    Keywords: PTrie; { of <String, TGrammarTokenKind> }
  End;

  TLexerRuleParser = Function(Lexer: PLexer): Boolean;

  PLexerRule = ^TLexerRule;

  TLexerRule = Record
    TokenKind: TGrammarTokenKind;
    Parser: TLexerRuleParser;
  End;

Procedure TGrammarLexer_Create(Var Self: PGrammarLexer; Const Source: PStream);
Procedure TGrammarLexer_Destroy(Self: PLexer);
Function TGrammarLexer_IsToken(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
Function TGrammarLexer_GetNextToken(Var Self: PLexer): Boolean;
Procedure TGrammarLexer_AddRule(Var Self: PLexer; Const Rule: TLexerRule);

Implementation

Uses
  SysUtils, StrUtil{$IFDEF USE_STRINGS}, strings{$ENDIF};

Var
  mTGrammarLexer_VMT: TLexer_VMT;

Procedure TGrammarLexer_Create(Var Self: PGrammarLexer; Const Source: PStream);
Begin
  New(Self); { Final }
  TLexer_Create(PLexer(Self), Source, True);
  Self^.Parent.VMT := @mTGrammarLexer_VMT;

  Self^.Keywords := TTrie_Create(SizeOf(TGrammarTokenKind));
  Self^.Keywords^.Root^.Data := Nil;
  Self^.RuleList := TList_Create(SizeOf(TLexerRule), 10);
  GetMem(Self^.Parent.CurrentToken.Kind, SizeOf(TGrammarTokenKind));
  PGrammarTokenKind(Self^.Parent.CurrentToken.Kind)^ := eUndefined;
End;

Procedure TGrammarLexer_Destroy(Self: PLexer);
Begin
  FreeMem(Self^.CurrentToken.Kind, SizeOf(TGrammarTokenKind));
  TTrie_Destroy(PGrammarLexer(Self)^.Keywords);
  TList_Destroy(PGrammarLexer(Self)^.RuleList);
  TLexer_Destroy(Self);
End;

Function TGrammarLexer_IsToken(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
Begin
  Result := PGrammarTokenKind(Self^.CurrentToken.Kind)^ = PGrammarTokenKind(TokenKind)^;
End;

Function TGrammarLexer_GetNextToken(Var Self: PLexer): Boolean;
Var
  I: TSize;
  mRule: PLexerRule;
  mKeyword: PGrammarTokenKind;
  mSelf: PGrammarLexer;
  mTokenKind: PGrammarTokenKind;
Begin
  mTokenKind := PGrammarTokenKind(Self^.CurrentToken.Kind);
  If mTokenKind^ = eEof Then
  Begin
    Result := False;
    Exit;
  End;
  While IsSpace(TLexer_PeekNextChar(Self)) Do
  Begin
    TLexer_Forward(Self, 1);
  End;

  mSelf := PGrammarLexer(Self);

  For I := 0 To Pred(mSelf^.RuleList^.Size) Do
  Begin
    mRule := PLexerRule(TList_Get(mSelf^.RuleList, I));
    FreeStr(Self^.CurrentToken.Error);
    Self^.CurrentToken.Error := strnew('');
    If mRule^.Parser(Self) Then
    Begin
      Result := (strcomp(Self^.CurrentToken.Error, '') = 0);
      If Result Then
      Begin
        mKeyword := PGrammarTokenKind(TTrie_Get(mSelf^.Keywords,
          Self^.CurrentToken.Value));
        If mKeyword <> nil Then
        Begin
          mTokenKind^ := mKeyword^;
        End
        Else
        Begin
          mTokenKind^ := mRule^.TokenKind;
        End;
      End
      Else
      Begin
        mTokenKind^ := eUndefined;
      End;
      Exit;
    End;
  End;

  Self^.CurrentToken.StartPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
  I := 0;
  While (Not IsSpace(TLexer_PeekNextChar(Self))) And (TLexer_PeekNextChar(Self) <> #0) Do
  Begin
    TLexer_Forward(Self, 1);
    Inc(I);
  End;
  mTokenKind^ := eUndefined;
  FreeStr(Self^.CurrentToken.Error);
  Self^.CurrentToken.Error := strnew('Illegal token.');
  TLexer_FetchNextToken(Self, I);
  Result := False;
End;

Procedure TGrammarLexer_AddRule(Var Self: PLexer; Const Rule: TLexerRule);
Begin
  TList_PushBack(PGrammarLexer(Self)^.RuleList, @Rule);
End;

Initialization
  mTGrammarLexer_VMT.Destory := TGrammarLexer_Destroy;
  mTGrammarLexer_VMT.IsToken := TGrammarLexer_IsToken;
  mTGrammarLexer_VMT.GetNextToken := TGrammarLexer_GetNextToken;
End.
