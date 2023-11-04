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

Procedure ModeStackElementDestructor(Const Element: Pointer);

Implementation

Uses
  SysUtils, StrUtil, Trie, NFA, TrmRNode{$IFDEF USE_STRINGS}, strings{$ENDIF};

Var
  mTCodeLexer_VMT: TLexer_VMT;

Procedure TCodeLexer_Create(Var Self: PCodeLexer; Const Source: PStream);
Begin
  New(Self); { Final }
  TLexer_Create(PLexer(Self), Source, False);
  Self^.Parent.VMT := @mTCodeLexer_VMT;

  Self^.GrammarNode := nil;
  Self^.Mode := TStack_Create(SizeOf(PChar), ModeStackElementDestructor);
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
  I: TSize;
  mTermRuleNode: PTermRuleNode;
  mSavePoint: TSize;
  mNextPos: TSize;
  mSelf: PCodeLexer;
  mMode: PChar;
  mTermRules: PList;
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
      If mTermRuleNode^.Skipped Then
      Begin
        Goto S;
      End
      Else
      Begin
        Result := True;
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

        If mTermRuleNode^.Skipped Then
        Begin
          Goto S;
        End
        Else
        Begin
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
  mMode: PChar;
Begin
  mMode := PPChar(TStack_Pop(PCodeLexer(Self)^.Mode))^;
  FreeStr(mMode);
End;

Procedure ModeStackElementDestructor(Const Element: Pointer);
Begin
  FreeStr(PPChar(Element)^);
End;

Initialization
  mTCodeLexer_VMT.Destory := TCodeLexer_Destroy;
  mTCodeLexer_VMT.IsToken := TCodeLexer_IsToken;
  mTCodeLexer_VMT.GetNextToken := TCodeLexer_GetNextToken;
End.
