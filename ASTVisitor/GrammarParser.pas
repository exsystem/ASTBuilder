Unit GrammarParser;

{$I define.inc}

Interface

Uses
  TypeDef, List, Lexer, ParseTree, ASTNode, GrammarNode;

Type
  PAstViewer = ^TAstViewer;

  TAstViewer = Record
    Parent: TAstVisitor;
    FGrammar: PGrammarNode;
    FLexer: PLexer;
    FTokenList: PList;
    FParseTree: PParseTree;
    FCurrentToken: TSize;
    FCurrentParseTreeNode: PParseTree;
    Error: PChar;
    Level: TSize;
  End;

Procedure TAstViewer_Create(Var Self: PAstViewer; Lexer: PLexer);

Procedure TAstViewer_Destroy(Self: PAstVisitor);

Procedure TAstViewer_VisitId(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitTerm(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitGroup(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitRule(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitTermRule(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitGrammar(Self: PAstVisitor; Node: PAstNode);

Function TAstViewer_Term(Self: PAstViewer; TokenKind: TTokenKind): Boolean; Overload;

Function TAstViewer_Term(Self: PAstViewer; GrammarTokenKind: TGrammarTokenKind): Boolean;
  Overload;

Function TAstViewer_Term(Self: PAstViewer; TermRule: PChar): Boolean; Overload;

Function TAstViewer_GetNextToken(Self: PAstViewer): Boolean;

Function TAstViewer_IsToken(Self: PAstViewer; TokenKind: TTokenKind): Boolean;

Function TAstViewer_GetCurrentToken(Self: PAstViewer): PToken;

Procedure TAstViewer_PrintParseTree(Self: PAstVisitor; ParseTree: PParseTree);

Procedure TAstViewer_WriteLn(Self: PAstVisitor; Content: PChar);

Procedure TAstViewer_Indent(Self: PAstVisitor);

Procedure TAstViewer_Deindent(Self: PAstVisitor);

Implementation

Uses
  IdNode, TermNode, GroupNode, RuleNode,
 {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StringUtils;

Var
  mTAstViewer_VMT: TAstVisitor_VMT;

Procedure TAstViewer_Create(Var Self: PAstViewer; Lexer: PLexer);
Begin
  New(Self); // Final
  TAstVisitor_Create(PAstVisitor(Self));
  Self.Parent.VMT := @mTAstViewer_VMT;

  Self.FLexer := Lexer;
  Self.FTokenList := TList_Create(SizeOf(TToken), 5);
  Self.FCurrentToken := 0;
  Self.Error := strnew('');
End;

Procedure TAstViewer_Destroy(Self: PAstVisitor);
Var
  mSelf: PAstViewer;
Begin
  mSelf := PAstViewer(Self);
  TList_Destroy(mSelf.FTokenList);
  FreeStr(mSelf.Error);
  TAstVisitor_Destroy(Self);
End;

Procedure TAstViewer_VisitId(Self: PAstVisitor; Node: PAstNode);
Var
  mSelf: PAstViewer;
  mNode: PIdNode;
  I: TSize;
  mRule: PRuleNode;
Begin
  mSelf := PAstViewer(Self);
  mNode := PIdNode(Node);
  For I := 0 To mSelf.FGrammar.Rules.Size - 1 Do
  Begin
    mRule := PPRuleNode(TList_Get(mSelf.FGrammar.Rules, I))^;
    If strcomp(mRule.Name, mNode.Value) = 0 Then
    Begin
      mRule.Parent.VMT.Accept(PAstNode(mRule), Self);
      Exit;
    End;
  End;
  FreeStr(mSelf.Error);
  mSelf.Error := strnew('Error.');
End;

Procedure TAstViewer_VisitTerm(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PTermNode;
  mSelf: PAstViewer;
  mTermNode: PParseTree;
Begin
  mNode := PTermNode(Node);
  mSelf := PAstViewer(Self);
  If TAstViewer_Term(mSelf, mNode.Token.Value) Then
  Begin
    New(mTermNode);
    mTermNode.RuleName := strnew('');
    mTermNode.Token := mSelf.FLexer.CurrentToken;
    mTermNode.Token.Error := StrNew(mTermNode.Token.Error);
    mTermNode.Token.Value := StrNew(mTermNode.Token.Value);
    mTermNode.Token.Kind.TermRule := StrNew(mTermNode.Token.Kind.TermRule);
    mTermNode.Children := nil;
    TList_PushBack(mSelf.FCurrentParseTreeNode.Children, @mTermNode);
    FreeStr(mSelf.Error);
    mSelf.Error := strnew('');
    Exit;
  End;
  FreeStr(mSelf.Error);
  mSelf.Error := strnew('Error.');
End;

Procedure TAstViewer_VisitGroup(Self: PAstVisitor; Node: PAstNode);
Var
  mSelf: PAstViewer;
  mNode: PGroupNode;
  I: TSize;
  mItem: PAstNode;
  mSavePoint: TSize;
Begin
  mSelf := PAstViewer(Self);
  mNode := PGroupNode(Node);
  If mNode.IsAlternational Then
  Begin
    Case mNode.GroupType Of
      TGroupType.eGroup:
      Begin
        For I := 0 To mNode.Terms.Size - 1 Do
        Begin
          mItem := PPAstNode(TList_Get(mNode.Terms, I))^;
          If mItem = nil Then
          Begin
            Break;
          End;
          FreeStr(mSelf.Error);
          mSelf.Error := strnew('');
          mItem.VMT.Accept(mItem, Self);
          If strcomp(mSelf.Error, '') = 0 Then
          Begin
            Break;
          End;
        End;
      End;
      TGroupType.eOptional:
      Begin
        For I := 0 To mNode.Terms.Size - 1 Do
        Begin
          mItem := PPAstNode(TList_Get(mNode.Terms, I))^;
          If mItem = nil Then
          Begin
            Break;
          End;
          FreeStr(mSelf.Error);
          mSelf.Error := strnew('');
          mItem.VMT.Accept(mItem, Self);
          If strcomp(mSelf.Error, '') = 0 Then
          Begin
            Break;
          End;
        End;
        FreeStr(mSelf.Error);
        mSelf.Error := strnew('');
      End;
      TGroupType.eMultiple:
      Begin
        FreeStr(mSelf.Error);
        mSelf.Error := strnew('');
        While strcomp(mSelf.Error, '') = 0 Do
        Begin
          For I := 0 To mNode.Terms.Size - 1 Do
          Begin
            FreeStr(mSelf.Error);
            mSelf.Error := strnew('');
            mItem := PPAstNode(TList_Get(mNode.Terms, I))^;
            If mItem = nil Then
            Begin
              Break;
            End;
            mItem.VMT.Accept(mItem, Self);
            If strcomp(mSelf.Error, '') = 0 Then
            Begin
              Break;
            End;
          End;
        End;
        FreeStr(mSelf.Error);
        mSelf.Error := strnew('');
      End;
    End;
  End
  Else
  Begin
    FreeStr(mSelf.Error);
    mSelf.Error := strnew('');
    Case mNode.GroupType Of
      TGroupType.eGroup:
      Begin
        mSavePoint := mSelf.FCurrentParseTreeNode.Children.Size;
        For I := 0 To mNode.Terms.Size - 1 Do
        Begin
          mItem := PPAstNode(TList_Get(mNode.Terms, I))^;
          If mItem = nil Then
          Begin
            Continue;
          End;
          mItem.VMT.Accept(mItem, Self);
          If strcomp(mSelf.Error, '') <> 0 Then
          Begin
            While mSelf.FCurrentParseTreeNode.Children.Size > mSavePoint Do
            Begin
              TParseTree_Destroy(
                PPParseTree(TList_Back(mSelf.FCurrentParseTreeNode.Children))^);
              TList_PopBack(mSelf.FCurrentParseTreeNode.Children);
            End;
            Break;
          End;
        End;
      End;
      TGroupType.eOptional:
      Begin
        mSavePoint := mSelf.FCurrentParseTreeNode.Children.Size;
        For I := 0 To mNode.Terms.Size - 1 Do
        Begin
          mItem := PPAstNode(TList_Get(mNode.Terms, I))^;
          If mItem = nil Then
          Begin
            Continue;
          End;
          mItem.VMT.Accept(mItem, Self);
          If strcomp(mSelf.Error, '') <> 0 Then
          Begin
            While mSelf.FCurrentParseTreeNode.Children.Size > mSavePoint Do
            Begin
              TParseTree_Destroy(
                PPParseTree(TList_Back(mSelf.FCurrentParseTreeNode.Children))^);
              TList_PopBack(mSelf.FCurrentParseTreeNode.Children);
            End;
            FreeStr(mSelf.Error);
            mSelf.Error := strnew('');
            Break;
          End;
        End;
      End;
      TGroupType.eMultiple:
      Begin
        FreeStr(mSelf.Error);
        mSelf.Error := strnew('');
        While strcomp(mSelf.Error, '') = 0 Do
        Begin
          mSavePoint := mSelf.FCurrentParseTreeNode.Children.Size;
          For I := 0 To mNode.Terms.Size - 1 Do
          Begin
            mItem := PPAstNode(TList_Get(mNode.Terms, I))^;
            If mItem = nil Then
            Begin
              Continue;
            End;
            mItem.VMT.Accept(mItem, Self);
            If strcomp(mSelf.Error, '') <> 0 Then
            Begin
              While mSelf.FCurrentParseTreeNode.Children.Size > mSavePoint Do
              Begin
                TParseTree_Destroy(
                  PPParseTree(TList_Back(mSelf.FCurrentParseTreeNode.Children))^);
                TList_PopBack(mSelf.FCurrentParseTreeNode.Children);
              End;
              FreeStr(mSelf.Error);
              mSelf.Error := strnew('');
              Exit;
            End;
          End;
        End;
      End;
    End;
  End;
End;

Procedure TAstViewer_VisitRule(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PRuleNode;
  mSelf: PAstViewer;
  mCurr: PParseTree;
  mOrig: PParseTree;
Begin
  mSelf := PAstViewer(Self);
  mNode := PRuleNode(Node);
  mOrig := mSelf.FCurrentParseTreeNode;
  New(mCurr);
  TList_PushBack(mOrig.Children, @mCurr);
  mSelf.FCurrentParseTreeNode := mCurr;
  mSelf.FCurrentParseTreeNode.RuleName := strnew(mNode.Name);
  mSelf.FCurrentParseTreeNode.Token.Error := strnew('');
  mSelf.FCurrentParseTreeNode.Token.Value := strnew('');
  mSelf.FCurrentParseTreeNode.Token.Kind.TermRule := strnew('');
  mSelf.FCurrentParseTreeNode.Children := TList_Create(SizeOf(PParseTree), 1);
  If mNode.Expr <> nil Then
  Begin
    mNode.Expr.Parent.VMT.Accept(PAstNode(mNode.Expr), Self);
  End;
  //  If mSelf.Error <> '' Then
  //  Begin
  //    While Not TList_IsEmpty(mCurr.Children) Do
  //    Begin
  //      Dispose(PPParseTree(TList_Back(mCurr.Children))^);
  //    End;
  //    TList_Destroy(mCurr.Children);
  //  End;
  mSelf.FCurrentParseTreeNode := mOrig;
End;

Procedure TAstViewer_VisitTermRule(Self: PAstVisitor; Node: PAstNode);
Begin
  WriteLn('TermRule');
End;

Procedure TAstViewer_VisitGrammar(Self: PAstVisitor; Node: PAstNode);
Var
  mItem: PAstNode;
  mSelf: PAstViewer;
  mNode: PGrammarNode;
Begin
  mSelf := PAstViewer(Self);
  mNode := PGrammarNode(Node);
  FreeStr(mSelf.Error);
  mSelf.Error := strnew('');
  If mNode.Rules.Size = 0 Then
  Begin
    mSelf.FParseTree := nil;
    Exit;
  End;
  mSelf.FGrammar := mNode;
  mSelf.FLexer.GrammarNode := mNode;
  New(mSelf.FParseTree);
  mSelf.FCurrentParseTreeNode := mSelf.FParseTree;
  mSelf.FCurrentParseTreeNode.RuleName := strnew('*');
  mSelf.FCurrentParseTreeNode.Token.Error := strnew('');
  mSelf.FCurrentParseTreeNode.Token.Value := strnew('');
  mSelf.FCurrentParseTreeNode.Token.Kind.TermRule := strnew('');
  mSelf.FCurrentParseTreeNode.Children := TList_Create(SizeOf(PParseTree), 1);
  mItem := PPAstNode(TList_Get(mNode.Rules, 0))^;
  mItem.VMT.Accept(mItem, Self);
End;

Function TAstViewer_Term(Self: PAstViewer; TokenKind: TTokenKind): Boolean;
Begin
  If (Self.FLexer.NextPos > 1) And (Self.FLexer.CurrentToken.Kind.TokenKind =
    eUndefined) Then
  Begin
    // Low effeciency! Should stopped the parser immediately! 
    // * Consider `E -> Term(A) or Term(B) or Term(C) ...`
    // * If an undefined token tested out during `Term(A)` with `False` returned, not because of not matching the `A`, you can not stop parsing E with this pattern of chaining terms together by `or`.
    // OR (BETTER CHOICE): Assuming the lexer has preprocessed already, so that it is guaranteed no incorrect tokens during parsing. So this IF-THEN code block should be completely removed!
    Result := False;
    Exit;
  End;
  If TAstViewer_GetNextToken(Self) Then
  Begin
    Result := TAstViewer_IsToken(Self, TokenKind);
    If Not Result Then
    Begin
      Dec(Self.FCurrentToken);
    End;
    Exit;
  End;
  Result := (TokenKind.TokenKind = eEof);
End;

Function TAstViewer_Term(Self: PAstViewer; GrammarTokenKind: TGrammarTokenKind): Boolean;
Var
  mTokenKind: TTokenKind;
Begin
  mTokenKind.TokenKind := GrammarTokenKind;
  Result := TAstViewer_Term(Self, mTokenKind);
End;

Function TAstViewer_Term(Self: PAstViewer; TermRule: PChar): Boolean;
Var
  mTokenKind: TTokenKind;
Begin
  mTokenKind.TokenKind := eUserDefined;
  mTokenKind.TermRule := TermRule;
  Result := TAstViewer_Term(Self, mTokenKind);
End;

Function TAstViewer_GetNextToken(Self: PAstViewer): Boolean;
Var
  mToken: PToken;
Begin
  If Self.FCurrentToken = Self.FTokenList.Size Then
  Begin
    Result := TLexer_GetNextToken(Self.FLexer);
    If Result Then
    Begin
      Inc(Self.FCurrentToken);
      (*
      InterlockedIncStringRefCount(@Self.FLexer.CurrentToken.Value);  // PATCHED LINE
      TList_PushBack(Self.FTokenList, @(Self.FLexer.CurrentToken));
      *)
      mToken := TList_EmplaceBack(Self.FTokenList); // USE EMPLACE
      mToken^ := Self.FLexer.CurrentToken;
    End;
  End
  Else
  Begin
    Result := True;
    Inc(Self.FCurrentToken);
  End;
End;

Function TAstViewer_IsToken(Self: PAstViewer; TokenKind: TTokenKind): Boolean;
Begin
  Result := TLexer_IsToken(Self.FLexer, TokenKind);
End;

Function TAstViewer_GetCurrentToken(Self: PAstViewer): PToken;
Begin
  Result := PToken(TList_Get(Self.FTokenList, Self.FCurrentToken - 1));
End;

Procedure TAstViewer_PrintParseTree(Self: PAstVisitor; ParseTree: PParseTree);
Var
  I: TSize;
Begin
  If strcomp(ParseTree.RuleName, '') = 0 Then
  Begin
    TAstViewer_WriteLn(Self, PChar(ParseTree.Token.Kind.TermRule +
      ': ' + ParseTree.Token.Value));
  End
  Else
  Begin
    TAstViewer_WriteLn(Self, ParseTree.RuleName);
    TAstViewer_Indent(Self);
    If (ParseTree.Children.Size > 0) And (PAstViewer(Self).Level < 15) Then
    Begin
      For i := 0 To ParseTree.Children.Size - 1 Do
      Begin
        TAstViewer_PrintParseTree(Self, PParseTree(TList_Get(ParseTree.Children, I)^));
      End;
    End;
    TAstViewer_Deindent(Self);
  End;
End;

Procedure TAstViewer_WriteLn(Self: PAstVisitor; Content: PChar);
Var
  I: TSize;
Begin
  If PAstViewer(Self).Level > 0 Then
  Begin
    For I := 0 To PAstViewer(Self).Level - 1 Do
    Begin
      Write('  ');
    End;
  End;
  Writeln(Content);
End;

Procedure TAstViewer_Indent(Self: PAstVisitor);
Begin
  Inc(PAstViewer(Self).Level);
End;

Procedure TAstViewer_Deindent(Self: PAstVisitor);
Begin
  Dec(PAstViewer(Self).Level);
End;

Begin
  mTAstViewer_VMT.Destory := TAstViewer_Destroy;
  mTAstViewer_VMT.VisitId := TAstViewer_VisitId;
  mTAstViewer_VMT.VisitTerm := TAstViewer_VisitTerm;
  mTAstViewer_VMT.VisitGroup := TAstViewer_VisitGroup;
  mTAstViewer_VMT.VisitRule := TAstViewer_VisitRule;
  mTAstViewer_VMT.VisitTermRule := TAstViewer_VisitTermRule;
  mTAstViewer_VMT.VisitGrammar := TAstViewer_VisitGrammar;

End.
