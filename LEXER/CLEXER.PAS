Unit CLexer;

{$I define.inc}

Interface

Uses
  List, STACK, TypeDef, Stream, GrmrNode, Lexer;

Type
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
Procedure TCodeLexer_Init(Var Self: PCodeLexer);
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
  PTermRule(Self^.Parent.CurrentToken.Kind) := TTermRule_Make(0);
End;

Procedure TCodeLexer_Destroy(Self: PLexer);
Begin
  TTermRule_Destroy(PTermRule(Self^.CurrentToken.Kind));
  TStack_Destroy(PCodeLexer(Self)^.Mode);
  TLexer_Destroy(Self);
End;

Function TCodeLexer_IsToken(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
Begin
  Result := (PTermRule(Self^.CurrentToken.Kind)^ = PTermRule(TokenKind)^);
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
  If PTermRule(Self^.CurrentToken.Kind)^ = 1 Then
  Begin
    Result := False;
    Exit;
  End;
  mSelf := PCodeLexer(Self);
  S:
    If TLexer_PeekNextChar(Self) = #0 Then
    Begin
      TTermRule_Destroy(PTermRule(Self^.CurrentToken.Kind));
      PTermRule(Self^.CurrentToken.Kind) := TTermRule_Make(1);
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
      TTermRule_Destroy(PTermRule(Self^.CurrentToken.Kind));
      PTermRule(Self^.CurrentToken.Kind) := TTermRule_Make(mTermRuleNode^.TermRuleId);
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
        TTermRule_Destroy(PTermRule(Self^.CurrentToken.Kind));
        PTermRule(Self^.CurrentToken.Kind) := TTermRule_Make(mTermRuleNode^.TermRuleId);

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

  TTermRule_Destroy(PTermRule(Self^.CurrentToken.Kind));
  PTermRule(Self^.CurrentToken.Kind) := TTermRule_Make(0);
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
  Dispose(mMode);
End;

Procedure TCodeLexer_Init(Var Self: PCodeLexer);
Begin
  TGrammarNode_RegisterTermRule(Self^.GrammarNode, '@HEREDOC_END');
End;

Procedure TCodeLexer_ProcessToken(Var Self: PCodeLexer);
Var
  mMode: PChar;
  mTokenValue: PChar;
  mKind: PChar;
Begin
  mMode := PPChar(TStack_Top(Self^.Mode))^;
  mTokenValue := Self^.Parent.CurrentToken.Value;
  mKind := TGrammarNode_GetTermRuleName(Self^.GrammarNode,
    PTermRule(Self^.Parent.CurrentToken.Kind)^);

  If StrComp(mMode, 'hereDoc') <> 0 Then
  Begin
    Exit;
  End;
  If StrComp(mKind, 'START_HEREDOC') = 0 Then
  Begin
    mHereDocId := SubStr(mTokenValue, 3, StrLen(mTokenValue) - 3);
    Exit;
  End;
  If StrComp(mKind, 'HEREDOC_TEXT') = 0 Then
  Begin
    If StrPos(mTokenValue, mHereDocId) = mTokenValue Then
    Begin
      PTermRule(Self^.Parent.CurrentToken.Kind)^ :=
        TGrammarNode_GetTermRuleId(Self^.GrammarNode, '@HEREDOC_END');
      TLexer_Retract(PLexer(Self), StrLen(Self^.Parent.CurrentToken.Value) -
        StrLen(mHereDocId));
      FreeStr(Self^.Parent.CurrentToken.Value);
      Self^.Parent.CurrentToken.Value := StrNew(mHereDocId);
      TCodeLexer_PopMode(PLexer(Self));
      FreeStr(mHereDocId);
    End;
    Exit;
  End;
End;

Procedure ModeStackElementDestructor(Const Element: Pointer);
Begin
  FreeStr(PPChar(Element)^);
  Dispose(PPChar(Element));
End;

Initialization
  mTCodeLexer_VMT.Destory := TCodeLexer_Destroy;
  mTCodeLexer_VMT.IsToken := TCodeLexer_IsToken;
  mTCodeLexer_VMT.GetNextToken := TCodeLexer_GetNextToken;
End.
