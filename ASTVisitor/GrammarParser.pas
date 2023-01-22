Unit GrammarParser;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

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
    Error: String;
  End;

Procedure TAstViewer_Create(Var Self: PAstViewer; Lexer: PLexer);

Procedure TAstViewer_Destroy(Self: PAstVisitor);

Procedure TAstViewer_VisitId(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitTerm(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitGroup(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitRule(Self: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitGrammar(Self: PAstVisitor; Node: PAstNode);

Function TAstViewer_Term(Self: PAstViewer; TokenKind: TTokenKind): Boolean;

Function TAstViewer_GetNextToken(Self: PAstViewer): Boolean;

Function TAstViewer_IsToken(Self: PAstViewer; TokenKind: TTokenKind): Boolean;

Function TAstViewer_GetCurrentToken(Self: PAstViewer): PToken;

Implementation

Uses
  IdNode, TermNode, GroupNode, RuleNode;

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
End;

Procedure TAstViewer_Destroy(Self: PAstVisitor);
Var
  mSelf: PAstViewer;
Begin
  mSelf := PAstViewer(Self);
  TList_Destroy(mSelf.FTokenList);
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
    If mRule.Name = mNode.Value Then
    Begin
      mRule.Parent.VMT.Accept(PAstNode(mRule), Self);
      Exit;
    End;
  End;
  mSelf.Error := 'Error.';
End;

Procedure TAstViewer_VisitTerm(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PTermNode;
  mSelf: PAstViewer;
  mTermNode: PParseTree;
  mTokenKind: TTokenKind;
Begin
  mNode := PTermNode(Node);
  mSelf := PAstViewer(Self);
  If TAstViewer_Term(mSelf, mTokenKind) Then
  Begin
    New(mTermNode);
    mTermNode.RuleName := '';
    mTermNode.Token := mNode.Token;
    TList_PushBack(mSelf.FCurrentParseTreeNode.Children, @mTermNode);
    WriteLn(mNode.Token.Value);
    mSelf.Error := '';
    Exit;
  End;
  mSelf.Error := 'Error.';
End;

Procedure TAstViewer_VisitGroup(Self: PAstVisitor; Node: PAstNode);
Var
  mSelf: PAstViewer;
  mNode: PGroupNode;
  I: TSize;
  mItem: PAstNode;
  mSavePoint: TSize;
  J: TSize;
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
          mItem.VMT.Accept(mItem, Self);
          If mSelf.Error = '' Then
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
          mItem.VMT.Accept(mItem, Self);
          If mSelf.Error = '' Then
          Begin
            Break;
          End;
        End;
        mSelf.Error := '';
      End;
      TGroupType.eMultiple:
      Begin
        While mSelf.Error = '' Do
        Begin
          For I := 0 To mNode.Terms.Size - 1 Do
          Begin
            mItem := PPAstNode(TList_Get(mNode.Terms, I))^;
            If mItem = nil Then
            Begin
              Break;
            End;
            mItem.VMT.Accept(mItem, Self);
            If mSelf.Error = '' Then
            Begin
              Break;
            End;
          End;
        End;
        mSelf.Error := '';
      End;
    End;
  End
  Else
  Begin
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
          If mSelf.Error <> '' Then
          Begin
            For J := mSavePoint To mSelf.FCurrentParseTreeNode.Children.Size - 1 Do
            Begin
              TList_Erase(mSelf.FCurrentParseTreeNode.Children, J);
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
          If mSelf.Error <> '' Then
          Begin
            For J := mSavePoint To mSelf.FCurrentParseTreeNode.Children.Size - 1 Do
            Begin
              TList_Erase(mSelf.FCurrentParseTreeNode.Children, J);
            End;
            mSelf.Error := '';
            Break;
          End;
        End;
      End;
      TGroupType.eMultiple:
      Begin
        While mSelf.Error = '' Do
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
            If mSelf.Error <> '' Then
            Begin
              For J := mSavePoint To mSelf.FCurrentParseTreeNode.Children.Size - 1 Do
              Begin
                TList_Erase(mSelf.FCurrentParseTreeNode.Children, J);
              End;
              mSelf.Error := '';
              Break;
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
  TList_PushBack(mSelf.FCurrentParseTreeNode.Children, @mCurr);
  mSelf.FCurrentParseTreeNode := mCurr;
  mSelf.FCurrentParseTreeNode.RuleName := mNode.Name;
  mSelf.FCurrentParseTreeNode.Children := TList_Create(SizeOf(PParseTree), 1);
  If mNode.Expr <> nil Then
  Begin
    mNode.Expr.Parent.VMT.Accept(PAstNode(mNode.Expr), Self);
  End;
  If mSelf.Error <> '' Then
  Begin
    TList_Destroy(mCurr.Children);
    Dispose(mCurr);
    TList_Erase(mSelf.FCurrentParseTreeNode.Children,
      mSelf.FCurrentParseTreeNode.Children.Size - 1);
  End;
  mSelf.FCurrentParseTreeNode := mOrig;
End;

Procedure TAstViewer_VisitGrammar(Self: PAstVisitor; Node: PAstNode);
Var
  mItem: PAstNode;
  mSelf: PAstViewer;
  mNode: PGrammarNode;
Begin
  mSelf := PAstViewer(Self);
  mNode := PGrammarNode(Node);
  mSelf.Error := '';
  If mNode.Rules.Size = 0 Then
  Begin
    mSelf.FParseTree := nil;
    Exit;
  End;
  mSelf.FGrammar := mNode;
  New(mSelf.FParseTree);
  mSelf.FCurrentParseTreeNode := mSelf.FParseTree;
  mSelf.FCurrentParseTreeNode.RuleName := '*';
  mSelf.FCurrentParseTreeNode.Children := TList_Create(SizeOf(PParseTree), 1);
  mItem := PPAstNode(TList_Get(mNode.Rules, 0))^;
  mItem.VMT.Accept(mItem, Self);
End;

Function TAstViewer_Term(Self: PAstViewer; TokenKind: TTokenKind): Boolean;
Begin
  If (Self.FLexer.NextPos > 1) And (Self.FLexer.CurrentToken.Kind = eUndefined) Then
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
  Result := (TokenKind = eEof);
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
  Result := (TAstViewer_GetCurrentToken(Self).Kind = TokenKind);
End;

Function TAstViewer_GetCurrentToken(Self: PAstViewer): PToken;
Begin
  Result := PToken(TList_Get(Self.FTokenList, Self.FCurrentToken - 1));
End;

Begin
  mTAstViewer_VMT.Destory := TAstViewer_Destroy;
  mTAstViewer_VMT.VisitId := TAstViewer_VisitId;
  mTAstViewer_VMT.VisitTerm := TAstViewer_VisitTerm;
  mTAstViewer_VMT.VisitGroup := TAstViewer_VisitGroup;
  mTAstViewer_VMT.VisitRule := TAstViewer_VisitRule;
  mTAstViewer_VMT.VisitGrammar := TAstViewer_VisitGrammar;

End.
