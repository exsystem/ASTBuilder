Unit CLexer;

{$I define.inc}

Interface

Uses
  List, STACK, TypeDef, Stream, GrmrNode, Lexer;

Type
  PCodeLexer = ^TCodeLexer;

  TCodeLexer_Init = Procedure(Var Self: PCodeLexer);
  TCodeLexer_ProcessToken = Procedure(Var Self: PCodeLexer);

  TCodeLexer = Record
    Parent: TLexer;
    GrammarNode: PGrammarNode;
    Mode: PStack; { Of PTChar }
    OnInit: TCodeLexer_Init;
    OnProcessToken: TCodeLexer_ProcessToken;
  End;

Procedure TCodeLexer_Create(Var Self: PCodeLexer; Const Source: PStream);
Procedure TCodeLexer_Destroy(Self: PLexer);
Function TCodeLexer_IsToken(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
Function TCodeLexer_GetNextToken(Var Self: PLexer): Boolean;
Procedure TCodeLexer_PushMode(Var Self: PLexer; Mode: PTChar);
Procedure TCodeLexer_PopMode(Var Self: PLexer);

Procedure ModeStackElementDestructor(Const Element: Pointer);

Implementation

Uses
  SysUtils, StrUtil, Trie, NFA, TrmRNode{$IFDEF USE_STRINGS}, strings{$ENDIF};

Var
  mTCodeLexer_VMT: TLexer_VMT;

Procedure TCodeLexer_Create(Var Self: PCodeLexer; Const Source: PStream);
Var
  mMode: PTChar;
Begin
  New(Self); { Final }
  TLexer_Create(PLexer(Self), Source, False);
  Self^.Parent.VMT := @mTCodeLexer_VMT;

  Self^.GrammarNode := nil;
  Self^.Mode := TStack_Create(SizeOf(PTChar), ModeStackElementDestructor);
  Self^.OnInit := nil;
  Self^.OnProcessToken := nil;
  mMode := TCharStrNew('');
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
  mMode: PTChar;
  mTermRules: PList;
  mSkip: Boolean;
  mCommand: PCommand;
  mChar: PTChar;
  mMatched: Boolean;
Label
  S;
Begin
  TLexer_PeekNextChar(Self);
  If PTermRule(Self^.CurrentToken.Kind)^ = 1 Then
  Begin
    Result := False;
    Exit;
  End;
  mSelf := PCodeLexer(Self);
  S:
    If Self^.CurrentCharSize = 0 Then
    Begin
      TTermRule_Destroy(PTermRule(Self^.CurrentToken.Kind));
      PTermRule(Self^.CurrentToken.Kind) := TTermRule_Make(1);
      Self^.CurrentToken.StartPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
      FreeStr(Self^.CurrentToken.Value);
      Self^.CurrentToken.Value := TCharStrNew('');
      Result := True;
      Exit;
    End;
  mNextPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
  mMode := PPTChar(TStack_Top(mSelf^.Mode))^;
  mTermRules := PPList(TTrie_Get(mSelf^.GrammarNode^.TermRules, mMode))^;
  For I := 0 To Pred(mTermRules^.Size) Do
  Begin
    mTermRuleNode := PPTermRuleNode(TList_Get(mTermRules, I))^;
    FreeStr(Self^.CurrentToken.Error);
    Self^.CurrentToken.Error := TCharStrNew('');
    Result := False;
    If TCharStrComp(mTermRuleNode^.Nfa^.Keyword, '') <> 0 Then
    Begin
      If Not TLexer_PeekNextWord(Self, mTermRuleNode^.Nfa^.Keyword) Then
      Begin
        Continue;
      End;
      TTermRule_Destroy(PTermRule(Self^.CurrentToken.Kind));
      PTermRule(Self^.CurrentToken.Kind) := TTermRule_Make(mTermRuleNode^.TermRuleId);
      Self^.CurrentToken.StartPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
      TLexer_FetchNextToken(Self, Self^.FLastPeekCharCount);

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
        If Assigned(mSelf^.OnProcessToken) Then
        Begin
          mSelf^.OnProcessToken(mSelf);
        End;
        Exit;
      End;
    End
    Else
    Begin
      TNfa_Reset(mTermRuleNode^.Nfa);
      Self^.CurrentToken.StartPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
      While True Do
      Begin
        mChar := TLexer_PeekNextChar(Self);
        If Self^.CurrentCharSize = 0 Then
          Break;
        mMatched := TNfa_Move(mTermRuleNode^.Nfa, mChar,
          Self^.CurrentCharSize, Self^.FStream^.Encoding,
          Not Self^.FCaseSensitive);
        If Not mMatched Then
          Break;
        TLexer_Forward(Self, 1);
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
          If Assigned(mSelf^.OnProcessToken) Then
          Begin
            mSelf^.OnProcessToken(mSelf);
          End;
          Exit;
        End;
      End;
      Self^.FStream^.VMT^.SetPosition(Self^.FStream, mNextPos);
    End;
  End;
  Self^.CurrentToken.StartPos := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
  I := 0;
  mChar := TLexer_PeekNextChar(Self);
  While Self^.CurrentCharSize <> 0 Do
  Begin
    TLexer_Forward(Self, 1);
    Inc(I);
    mChar := TLexer_PeekNextChar(Self);
  End;

  TTermRule_Destroy(PTermRule(Self^.CurrentToken.Kind));
  PTermRule(Self^.CurrentToken.Kind) := TTermRule_Make(0);
  FreeStr(Self^.CurrentToken.Error);
  Self^.CurrentToken.Error := TCharStrNew('Illegal token.');
  TLexer_FetchNextToken(Self, I);
  Result := False;
End;

Procedure TCodeLexer_PushMode(Var Self: PLexer; Mode: PTChar);
Var
  mMode: PTChar;
Begin
  mMode := TCharStrNew(Mode);
  TStack_Push(PCodeLexer(Self)^.Mode, @mMode);
End;

Procedure TCodeLexer_PopMode(Var Self: PLexer);
Var
  mMode: PPTChar;
Begin
  mMode := PPTChar(TStack_Pop(PCodeLexer(Self)^.Mode));
  FreeStr(mMode^);
  Dispose(mMode);
End;

Procedure ModeStackElementDestructor(Const Element: Pointer);
Begin
  FreeStr(PPTChar(Element)^);
  Dispose(PPTChar(Element));
End;

Initialization
  mTCodeLexer_VMT.Destory := TCodeLexer_Destroy;
  mTCodeLexer_VMT.IsToken := TCodeLexer_IsToken;
  mTCodeLexer_VMT.GetNextToken := TCodeLexer_GetNextToken;
End.
