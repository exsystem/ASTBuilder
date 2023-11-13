Unit CLexer;

{$I define.inc}

Interface

Uses
  List, STACK, TypeDef, Stream, GrmrNode, Lexer;

Type
  TTermRule = PChar;

  PCodeLexer = ^TCodeLexer;

  TCodeLexer = Record
    Parent: TLexer;
    GrammarNode: PGrammarNode;
    Mode: PStack; { Of PChar }
  End;

Procedure TCodeLexer_Create(Var Self: PCodeLexer; Const Source: PStream);
Procedure TCodeLexer_Destroy(Self: PLexer);
Function TCodeLexer_IsToken(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
Function TCodeLexer_GetNextToken(Var Self: PLexer): Boolean;
Procedure TCodeLexer_PushMode(Var Self: PLexer; Mode: PChar);
Procedure TCodeLexer_PopMode(Var Self: PLexer);
Procedure TCodeLexer_ProcessToken(Var Self: PCodeLexer);

Procedure ModeStackElementDestructor(Const Element: Pointer);

Implementation

Uses
  SysUtils, StrUtil, Trie, NFA, TrmRNode{$IFDEF USE_STRINGS}, strings{$ENDIF};

Var
  mTCodeLexer_VMT: TLexer_VMT;
  mHereDocId: PChar;

Procedure TCodeLexer_Create(Var Self: PCodeLexer; Const Source: PStream);
Var
  mMode: PChar;
Begin
  New(Self); { Final }
  TLexer_Create(PLexer(Self), Source, False);
  Self^.Parent.VMT := @mTCodeLexer_VMT;

  Self^.GrammarNode := nil;
  Self^.Mode := TStack_Create(SizeOf(PChar), ModeStackElementDestructor);
  mMode := StrNew('');
  TStack_Push(Self^.Mode, @mMode);
  TTermRule(Self^.Parent.CurrentToken.Kind) := StrNew('');
End;

Procedure TCodeLexer_Destroy(Self: PLexer);
Begin
  FreeStr(TTermRule(Self^.CurrentToken.Kind));
  TStack_Destroy(PCodeLexer(Self)^.Mode);
  TLexer_Destroy(Self);
End;

Function TCodeLexer_IsToken(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
Begin
  Result := (StrComp(TTermRule(Self^.CurrentToken.Kind), TTermRule(TokenKind)) = 0);
End;

Function TCodeLexer_GetNextToken(Var Self: PLexer): Boolean;
Var
  I, J: TSize;
  mTermRuleNode: PTermRuleNode;
  mSavePoint: TSize;
  mNextPos: TSize;
  mSelf: PCodeLexer;
  mMode: PChar;
  mTermRules: PList;
  mSkip: Boolean;
  mCommand: PCommand;
Label
  S;
Begin
  If StrComp(TTermRule(Self^.CurrentToken.Kind), 'EOF') = 0 Then
  Begin
    Result := False;
    Exit;
  End;
  mSelf := PCodeLexer(Self);
  S:
    If TLexer_PeekNextChar(Self) = #0 Then
    Begin
      FreeStr(TTermRule(Self^.CurrentToken.Kind));
      TTermRule(Self^.CurrentToken.Kind) := strnew('EOF');
      Self^.CurrentToken.StartPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
      FreeStr(Self^.CurrentToken.Value);
      Self^.CurrentToken.Value := StrNew('');
      TLexer_Forward(Self, 1);
      Result := True;
      Exit;
    End;
  mNextPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
  mMode := PPChar(TStack_Top(mSelf^.Mode))^;
  mTermRules := PPList(TTrie_Get(mSelf^.GrammarNode^.TermRules, mMode))^;
  For I := 0 To Pred(mTermRules^.Size) Do
  Begin
    mTermRuleNode := PPTermRuleNode(TList_Get(mTermRules, I))^;
    FreeStr(Self^.CurrentToken.Error);
    Self^.CurrentToken.Error := strnew('');
    Result := False;
    If strcomp(mTermRuleNode^.Nfa^.Keyword, '') <> 0 Then
    Begin
      If Not TLexer_PeekNextWord(Self, mTermRuleNode^.Nfa^.Keyword) Then
      Begin
        Continue;
      End;
      FreeStr(TTermRule(Self^.CurrentToken.Kind));
      TTermRule(Self^.CurrentToken.Kind) := strnew(mTermRuleNode^.Name);
      Self^.CurrentToken.StartPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
      FreeStr(Self^.CurrentToken.Value);
      Self^.CurrentToken.Value := CreateStr(StrLen(mTermRuleNode^.Nfa^.Keyword));
      Self^.FStream^.VMT^.Read(Self^.FStream, Self^.CurrentToken.Value^,
        StrLen(mTermRuleNode^.Nfa^.Keyword));

      mSkip := False;
      If Not TList_IsEmpty(mTermRuleNode^.CommandList) Then
      Begin
        For J := 0 To Pred(mTermRuleNode^.CommandList^.Size) Do
        Begin
          mCommand := PCommand(TList_Get(mTermRuleNode^.CommandList, J));
          Case mCommand^.CommandType Of
            eSkipCommand:
            Begin
              mSkip := True;
            End;
            ePushModeCommand:
            Begin
              TCodeLexer_PushMode(Self, mCommand^.Arg);
            End;
            ePopModeCommand:
            Begin
              TCodeLexer_PopMode(Self);
            End;
          End;
        End;
      End;

      If mSkip Then
      Begin
        Goto S;
      End
      Else
      Begin
        Result := True;
        TCodeLexer_ProcessToken(mSelf);
        Exit;
      End;
    End
    Else
    Begin
      TNfa_Reset(mTermRuleNode^.Nfa);
      Self^.CurrentToken.StartPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
      While TNfa_Move(mTermRuleNode^.Nfa, TLexer_PeekNextChar(Self),
          Not Self^.FCaseSensitive) Do
      Begin
        TLexer_Forward(Self, 1); { overflow }
        If TNfa_Accepted(mTermRuleNode^.Nfa) Then
        Begin
          Result := True;
          mSavePoint := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
          Continue;
        End;
      End;
      If Result Then
      Begin
        TLexer_FetchNextToken(Self, mSavePoint - Self^.CurrentToken.StartPos);
        FreeStr(TTermRule(Self^.CurrentToken.Kind));
        TTermRule(Self^.CurrentToken.Kind) := strnew(mTermRuleNode^.Name);

        mSkip := False;
        If Not TList_IsEmpty(mTermRuleNode^.CommandList) Then
        Begin
          For J := 0 To Pred(mTermRuleNode^.CommandList^.Size) Do
          Begin
            mCommand := PCommand(TList_Get(mTermRuleNode^.CommandList, J));
            Case mCommand^.CommandType Of
              eSkipCommand:
              Begin
                mSkip := True;
              End;
              ePushModeCommand:
              Begin
                TCodeLexer_PushMode(Self, mCommand^.Arg);
              End;
              ePopModeCommand:
              Begin
                TCodeLexer_PopMode(Self);
              End;
            End;
          End;
        End;

        If mSkip Then
        Begin
          Goto S;
        End
        Else
        Begin
          TCodeLexer_ProcessToken(mSelf);
          Exit;
        End;
      End;
      Self^.FStream^.VMT^.SetPosition(Self^.FStream, mNextPos);
    End;
  End;
  Self^.CurrentToken.StartPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
  I := 0;
  While TLexer_PeekNextChar(Self) <> #0 Do
  Begin
    TLexer_Forward(Self, 1);
    Inc(I);
  End;

  FreeStr(TTermRule(Self^.CurrentToken.Kind));
  TTermRule(Self^.CurrentToken.Kind) := strnew('');
  FreeStr(Self^.CurrentToken.Error);
  Self^.CurrentToken.Error := strnew('Illegal token.');
  TLexer_FetchNextToken(Self, I);
  Result := False;
End;

Procedure TCodeLexer_PushMode(Var Self: PLexer; Mode: PChar);
Var
  mMode: PChar;
Begin
  mMode := StrNew(Mode);
  TStack_Push(PCodeLexer(Self)^.Mode, @mMode);
End;

Procedure TCodeLexer_PopMode(Var Self: PLexer);
Var
  mMode: PPChar;
Begin
  mMode := PPChar(TStack_Pop(PCodeLexer(Self)^.Mode));
  FreeStr(mMode^);
  FreeMem(mMode);
End;

Procedure TCodeLexer_ProcessToken(Var Self: PCodeLexer);
Var
  mMode: PChar;
  mTokenValue: PChar;
  mKind: PChar;
  mEnding: PChar;
Begin
  mMode := PPChar(TStack_Top(Self^.Mode))^;
  mTokenValue := Self^.Parent.CurrentToken.Value;
  mKind := TTermRule(Self^.Parent.CurrentToken.Kind);

  If StrComp(mMode, 'hereDoc') <> 0 Then
    Exit;
  If StrComp(mKind, 'STARTHEREDOC') = 0 Then
  Begin
    mHereDocId := SubStr(mTokenValue, 3, Length(mTokenValue) - 3);
    Exit;
  End;
  If StrComp(mKind, 'HEREDOCTEXT') = 0 Then
  Begin
    mEnding := CreateStr(Length(mHereDocId) + 1);
    StrCat(mEnding, mHereDocId);
    StrCat(mEnding, ';');
    { If StrComp(mTokenValue, mEnding) = 0 Then }
    If TrimRight(StrPas(mTokenValue)) = StrPas(mEnding) Then
    Begin
      FreeStr(mKind);
      TTermRule(Self^.Parent.CurrentToken.Kind) := StrNew('_SEMI_HEREDOC');
      TCodeLexer_PopMode(PLexer(Self));
      FreeStr(mHereDocId);
    End;
    FreeStr(mEnding);
    Exit;
  End;
End;

Procedure ModeStackElementDestructor(Const Element: Pointer);
Begin
  FreeStr(PPChar(Element)^);
  FreeMem(PPChar(Element));
End;

Initialization
  mTCodeLexer_VMT.Destory := TCodeLexer_Destroy;
  mTCodeLexer_VMT.IsToken := TCodeLexer_IsToken;
  mTCodeLexer_VMT.GetNextToken := TCodeLexer_GetNextToken;
End.
