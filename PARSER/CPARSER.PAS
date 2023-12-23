{ Unit CodeParser; }
Unit CPARSER;

{$I define.inc}

Interface

Uses
  TypeDef, List, Stack, Lexer, ParseTr, ASTNode, GrmrNode, PARSER, CLEXER, STREAM;

Type

  PAstViewer = ^TAstViewer;

  TAstViewer = Record
    Parent: TParser;
    As_IAstVisitor: PAstVisitor;
    FGrammar: PGrammarNode;
    FParseTree: PParseTree;
    FCurrentParseTreeNode: PParseTree;
    Error: Boolean;
    ErrorMessages: PStack; { Of PChar }
    Level: TSize;

    FTreeOffset: TSize;
    FTreeFile: PStream;
    FStrOffset: TSize;
    FStrFile: PStream;

  End;

Procedure TAstViewer_Create(Var Self: PAstViewer; Lexer: PLexer);

Procedure TAstViewer_Destroy(Const Self: PParser);

Procedure TAstViewer_VisitId(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitTerm(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitGroup(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitRule(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitTermRule(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitGrammar(Intf: PAstVisitor; Node: PAstNode);

Function TAstViewer_IsTokenKindUndefined(Const TokenKind: Pointer): Boolean;

Function TAstViewer_IsTokenKindEof(Const TokenKind: Pointer): Boolean;

Function TAstViewer_CopyTokenKind(Const TokenKind: Pointer): Pointer;

Function TAstViewer_CompareTokenKind(Self: PParser; Const LHS: Pointer;
  Const RHS: Pointer): Boolean;

Procedure TAstViewer_PrintParseTree(Self: PAstViewer; ParseTree: PParseTree);

Procedure TAstViewer_OutputParseTree(Self: PAstViewer; Path: String);

Procedure TAstViewer_DoOuputNode(Self: PAstViewer; ParseTree: PParseTree; Parent: TSize);

Procedure TAstViewer_WriteLn(Self: PAstViewer; Content: PChar);

Procedure TAstViewer_Indent(Self: PAstViewer);

Procedure TAstViewer_Deindent(Self: PAstViewer);

Function TAstViewer_Term(Parser: PParser; TokenKind: TTermRule): Boolean;

Implementation

Uses
  IdNode, TrmNode, GrpNode, RuleNode,
 {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

Var
  mTAstViewer_VMT: TParser_VMT;
  mTAstViewer_Methods: TAstVisitor_Methods;

Procedure TAstViewer_Create(Var Self: PAstViewer; Lexer: PLexer);
Begin
  New(Self); { Final }
  TParser_Create(PParser(Self), Lexer);
  New(Self^.As_IAstVisitor);
  Self^.Parent.VMT := @mTAstViewer_VMT;
  Self^.As_IAstVisitor^.Instance := Self;
  Self^.As_IAstVisitor^.Methods := @mTAstViewer_Methods;

  { TODO: Merge with PChar Error fields in the parent class. }
  Self^.Error := False;
  Self^.ErrorMessages := TStack_Create(SizeOf(PChar), nil);
End;

Procedure TAstViewer_Destroy(Const Self: PParser);
Var
  mSelf: PAstViewer;
  I: TSize;
  mToken: PToken;
  mErrMsg: PPChar;
Begin
  mSelf := PAstViewer(Self);
  For I := 0 To Self^.FTokenList^.Size - 1 Do
  Begin
    mToken := PToken(TList_Get(Self^.FTokenList, I));
    Dispose(PSize(mToken^.Kind));
  End;
  { TODO: Merge with PChar Error fields in the parent class. }
  While Not TStack_Empty(mSelf^.ErrorMessages) Do
  Begin
    mErrMsg := TStack_Pop(mSelf^.ErrorMessages);
    FreeStr(mErrMsg^);
    FreeMem(mErrMsg, SizeOf(PPChar));
  End;
  TStack_Destroy(mSelf^.ErrorMessages);
  Dispose(mSelf^.As_IAstVisitor);
  TParser_Destroy(Self);
End;

Procedure TAstViewer_VisitId(Intf: PAstVisitor; Node: PAstNode);
Var
  mSelf: PAstViewer;
  mNode: PIdNode;
  I: TNonTermRuleId;
  mRule: PRuleNode;
Begin
  mSelf := PAstViewer(Intf^.Instance);
  mNode := PIdNode(Node);
  I := TGrammarNode_GetNonTermRuleId(mSelf^.FGrammar, mNode^.Value);
  mRule := PPRuleNode(TList_Get(mSelf^.FGrammar^.Rules, I - 2))^;
  mRule^.Parent.VMT^.Accept(PAstNode(mRule), Intf);
End;

Procedure TAstViewer_VisitTerm(Intf: PAstVisitor; Node: PAstNode);
Var
  mNode: PTermNode;
  mSelf: PAstViewer;
  mTermNode: PParseTree;
  mCurrToken: PToken;
  mErrMsg: PChar;
  S1, S2, S3: PChar;
Begin
  mNode := PTermNode(Node);
  mSelf := PAstViewer(Intf^.Instance);
  { Maybe check if term rule exists by mNode^.Token.Value first? }
  If TAstViewer_Term(PParser(mSelf), TGrammarNode_GetTermRuleId(
    mSelf^.FGrammar, mNode^.Token.Value)) Then
  Begin
    New(mTermNode);
    mTermNode^.RuleId := 0;
    mCurrToken := TParser_GetCurrentToken(PParser(mSelf));
    mTermNode^.Token.Error := StrNew(mCurrToken^.Error);
    mTermNode^.Token.Value := StrNew(mCurrToken^.Value);
    PTermRule(mTermNode^.Token.Kind) := TTermRule_Make(PTermRule(mCurrToken^.Kind)^);
    mTermNode^.Token.StartPos := mCurrToken^.StartPos;
    mTermNode^.Children := nil;
    TList_PushBack(mSelf^.FCurrentParseTreeNode^.Children, @mTermNode);
    mSelf^.Error := False;
    Exit;
  End;
  mSelf^.Error := True;
  If mSelf^.Parent.FCurrentToken = mSelf^.Parent.FTokenList^.Size - 1 Then
  Begin
    mCurrToken := PToken(TList_Get(mSelf^.Parent.FTokenList,
      mSelf^.Parent.FCurrentToken));
    S1 := 'Expecting term `';
    S2 := '`, but `';
    S3 := '` was found.';
    mErrMsg := CreateStr(StrLen(S1) + StrLen(mNode^.Token.Value) +
      StrLen(S2) + StrLen(mCurrToken^.Value) + StrLen(S3));
    strcat(mErrMsg, S1);
    strcat(mErrMsg, mNode^.Token.Value);
    strcat(mErrMsg, S2);
    strcat(mErrMsg, mCurrToken^.Value);
    strcat(mErrMsg, S3);
    TStack_Push(mSelf^.ErrorMessages, @mErrMsg);
  End;
End;

Procedure TAstViewer_VisitGroup(Intf: PAstVisitor; Node: PAstNode);
Var
  mSelf: PAstViewer;
  mNode: PGroupNode;
  I: TSize;
  mItem: PAstNode;
  mSavePoint: TSize;
  mLexerSavePoint: TSize;
  mPassed: Boolean;
Begin
  mSelf := PAstViewer(Intf^.Instance);
  mNode := PGroupNode(Node);
  If mNode^.IsAlternational Then
  Begin
    Case mNode^.GroupType Of
      eGroup:
      Begin
        For I := 0 To mNode^.Terms^.Size - 1 Do
        Begin
          mItem := PPAstNode(TList_Get(mNode^.Terms, I))^;
          If mItem = nil Then
          Begin
            Break;
          End;
          mSelf^.Error := False;
          mItem^.VMT^.Accept(mItem, Intf);
          If Not mSelf^.Error Then
          Begin
            Break;
          End;
        End;
      End;
      eOptional:
      Begin
        For I := 0 To mNode^.Terms^.Size - 1 Do
        Begin
          mItem := PPAstNode(TList_Get(mNode^.Terms, I))^;
          If mItem = nil Then
          Begin
            Break;
          End;
          mSelf^.Error := False;
          mItem^.VMT^.Accept(mItem, Intf);
          If Not mSelf^.Error Then
          Begin
            Break;
          End;
        End;
        mSelf^.Error := False;
      End;
      eOneOrMore:
      Begin
        mPassed := False;
        Repeat
          For I := 0 To mNode^.Terms^.Size - 1 Do
          Begin
            mSelf^.Error := False;
            mItem := PPAstNode(TList_Get(mNode^.Terms, I))^;
            If mItem = nil Then
            Begin
              mPassed := True;
              Break;
            End;
            mItem^.VMT^.Accept(mItem, Intf);
            If Not mSelf^.Error Then
            Begin
              mPassed := True;
              Break;
            End;
          End;
        Until mSelf^.Error;
        If mPassed Then
        Begin
          mSelf^.Error := False;
        End;
      End;
      eMultiple:
      Begin
        mSelf^.Error := False;
        While Not mSelf^.Error Do
        Begin
          For I := 0 To mNode^.Terms^.Size - 1 Do
          Begin
            mSelf^.Error := False;
            mItem := PPAstNode(TList_Get(mNode^.Terms, I))^;
            If mItem = nil Then
            Begin
              Break;
            End;
            mItem^.VMT^.Accept(mItem, Intf);
            If Not mSelf^.Error Then
            Begin
              Break;
            End;
          End;
        End;
        mSelf^.Error := False;
      End;
    End;
  End
  Else
  Begin
    mSelf^.Error := False;
    Case mNode^.GroupType Of
      eGroup:
      Begin
        mSavePoint := mSelf^.FCurrentParseTreeNode^.Children^.Size;
        mLexerSavePoint := mSelf^.Parent.FCurrentToken;
        For I := 0 To mNode^.Terms^.Size - 1 Do
        Begin
          mItem := PPAstNode(TList_Get(mNode^.Terms, I))^;
          If mItem = nil Then
          Begin
            Continue;
          End;
          mItem^.VMT^.Accept(mItem, Intf);
          If mSelf^.Error Then
          Begin
            mSelf^.Parent.FCurrentToken := mLexerSavePoint;
            While mSelf^.FCurrentParseTreeNode^.Children^.Size > mSavePoint Do
            Begin
              TParseTree_Destroy(
                PPParseTree(TList_Back(mSelf^.FCurrentParseTreeNode^.Children))^);
              TList_PopBack(mSelf^.FCurrentParseTreeNode^.Children);
            End;
            Break;
          End;
        End;
      End;
      eOptional:
      Begin
        mSavePoint := mSelf^.FCurrentParseTreeNode^.Children^.Size;
        mLexerSavePoint := mSelf^.Parent.FCurrentToken;
        For I := 0 To mNode^.Terms^.Size - 1 Do
        Begin
          mItem := PPAstNode(TList_Get(mNode^.Terms, I))^;
          If mItem = nil Then
          Begin
            Continue;
          End;
          mItem^.VMT^.Accept(mItem, Intf);
          If mSelf^.Error Then
          Begin
            mSelf^.Parent.FCurrentToken := mLexerSavePoint;
            While mSelf^.FCurrentParseTreeNode^.Children^.Size > mSavePoint Do
            Begin
              TParseTree_Destroy(
                PPParseTree(TList_Back(mSelf^.FCurrentParseTreeNode^.Children))^);
              TList_PopBack(mSelf^.FCurrentParseTreeNode^.Children);
            End;
            mSelf^.Error := False;
            Break;
          End;
        End;
      End;
      eOneOrMore:
      Begin
        mPassed := False;
        Repeat
          mSavePoint := mSelf^.FCurrentParseTreeNode^.Children^.Size;
          mLexerSavePoint := mSelf^.Parent.FCurrentToken;
          For I := 0 To mNode^.Terms^.Size - 1 Do
          Begin
            mItem := PPAstNode(TList_Get(mNode^.Terms, I))^;
            If mItem = nil Then
            Begin
              Continue;
            End;
            mItem^.VMT^.Accept(mItem, Intf);
            If mSelf^.Error Then
            Begin
              mSelf^.Parent.FCurrentToken := mLexerSavePoint;
              While mSelf^.FCurrentParseTreeNode^.Children^.Size > mSavePoint Do
              Begin
                TParseTree_Destroy(
                  PPParseTree(TList_Back(mSelf^.FCurrentParseTreeNode^.Children))^);
                TList_PopBack(mSelf^.FCurrentParseTreeNode^.Children);
              End;
              If mPassed Then
              Begin
                mSelf^.Error := False;
              End;
              Exit;
            End;
          End;
          mPassed := True;
        Until mSelf^.Error;
      End;
      eMultiple:
      Begin
        mSelf^.Error := False;
        While Not mSelf^.Error Do
        Begin
          mSavePoint := mSelf^.FCurrentParseTreeNode^.Children^.Size;
          mLexerSavePoint := mSelf^.Parent.FCurrentToken;
          For I := 0 To mNode^.Terms^.Size - 1 Do
          Begin
            mItem := PPAstNode(TList_Get(mNode^.Terms, I))^;
            If mItem = nil Then
            Begin
              Continue;
            End;
            mItem^.VMT^.Accept(mItem, Intf);
            If mSelf^.Error Then
            Begin
              mSelf^.Parent.FCurrentToken := mLexerSavePoint;
              While mSelf^.FCurrentParseTreeNode^.Children^.Size > mSavePoint Do
              Begin
                TParseTree_Destroy(
                  PPParseTree(TList_Back(mSelf^.FCurrentParseTreeNode^.Children))^);
                TList_PopBack(mSelf^.FCurrentParseTreeNode^.Children);
              End;
              mSelf^.Error := False;
              Exit;
            End;
          End;
        End;
      End;
    End;
  End;
End;

Procedure TAstViewer_VisitRule(Intf: PAstVisitor; Node: PAstNode);
Var
  mNode: PRuleNode;
  mSelf: PAstViewer;
  mCurr: PParseTree;
  mOrig: PParseTree;
Begin
  mSelf := PAstViewer(Intf^.Instance);
  mNode := PRuleNode(Node);
  mOrig := mSelf^.FCurrentParseTreeNode;
  New(mCurr);
  TList_PushBack(mOrig^.Children, @mCurr);
  mSelf^.FCurrentParseTreeNode := mCurr;
  mSelf^.FCurrentParseTreeNode^.RuleId := mNode^.Id;
  mSelf^.FCurrentParseTreeNode^.Token.Error := strnew('');
  mSelf^.FCurrentParseTreeNode^.Token.Value := strnew('');
  PTermRule(mSelf^.FCurrentParseTreeNode^.Token.Kind) := TTermRule_Make(0);
  mSelf^.FCurrentParseTreeNode^.Children := TList_Create(SizeOf(PParseTree), 1);
  If mNode^.Expr <> nil Then
  Begin
    mNode^.Expr^.Parent.VMT^.Accept(PAstNode(mNode^.Expr), Intf);
  End;
  (*
  //  If mSelf^.Error <> '' Then
  //  Begin
  //    While Not TList_IsEmpty(mCurr^.Children) Do
  //    Begin
  //      Dispose(PPParseTree(TList_Back(mCurr^.Children))^);
  //    End;
  //    TList_Destroy(mCurr^.Children);
  //  End;
  *)
  mSelf^.FCurrentParseTreeNode := mOrig;
End;

Procedure TAstViewer_VisitTermRule(Intf: PAstVisitor; Node: PAstNode);
Begin
  WriteLn('TermRule');
End;

Procedure TAstViewer_VisitGrammar(Intf: PAstVisitor; Node: PAstNode);
Var
  mItem: PAstNode;
  mSelf: PAstViewer;
  mNode: PGrammarNode;
Begin
  mSelf := PAstViewer(Intf^.Instance);
  mNode := PGrammarNode(Node);
  mSelf^.Error := False;
  If mNode^.Rules^.Size = 0 Then
  Begin
    mSelf^.FParseTree := nil;
    Exit;
  End;
  mSelf^.FGrammar := mNode;
  PCodeLexer(mSelf^.Parent.FLexer)^.GrammarNode := mNode;
  TCodeLexer_Init(PCodeLexer(mSelf^.Parent.FLexer));
  mSelf^.Parent.FLexer^.FCaseSensitive :=
    Not mNode^.Options[COption_CaseInsensitive].BooleanValue;
  New(mSelf^.FParseTree);
  mSelf^.FCurrentParseTreeNode := mSelf^.FParseTree;
  mSelf^.FCurrentParseTreeNode^.RuleId := 1; {***}
  mSelf^.FCurrentParseTreeNode^.Token.Error := strnew('');
  mSelf^.FCurrentParseTreeNode^.Token.Value := strnew('');
  PTermRule(mSelf^.FCurrentParseTreeNode^.Token.Kind) := TTermRule_Make(0);
  mSelf^.FCurrentParseTreeNode^.Children := TList_Create(SizeOf(PParseTree), 1);
  mItem := PPAstNode(TList_Get(mNode^.Rules, 0))^;
  mItem^.VMT^.Accept(mItem, Intf);
End;

Function TAstViewer_IsTokenKindUndefined(Const TokenKind: Pointer): Boolean;
Begin
  Result := (PTermRule(TokenKind)^ = 0);
End;

Function TAstViewer_IsTokenKindEof(Const TokenKind: Pointer): Boolean;
Begin
  Result := (PTermRule(TokenKind)^ = 1);
End;

Function TAstViewer_CopyTokenKind(Const TokenKind: Pointer): Pointer;
Begin
  Result := TSize_Make(PTermRule(TokenKind)^);
End;

Function TAstViewer_CompareTokenKind(Self: PParser; Const LHS: Pointer;
  Const RHS: Pointer): Boolean;
Begin
  Result := (PTermRule(LHS)^ = PTermRule(RHS)^) Or (PTermRule(LHS)^
    >= PAstViewer(Self)^.FGrammar^.TermRulesCount);
End;

Procedure TAstViewer_PrintParseTree(Self: PAstViewer; ParseTree: PParseTree);
Var
  I: TSize;
  mLine: PChar;
Begin
  If ParseTree^.RuleId = 0 Then
  Begin
    mLine := strnew(TGrammarNode_GetTermRuleName(Self^.FGrammar,
      PTermRule(ParseTree^.Token.Kind)^));
    mLine := ReallocStr(mLine, StrLen(mLine) + StrLen(': ') +
      StrLen(ParseTree^.Token.Value));
    strcat(mLine, ': ');
    strcat(mLine, ParseTree^.Token.Value);
    TAstViewer_WriteLn(Self, mLine);
    FreeStr(mLine);
  End
  Else
  Begin
    TAstViewer_WriteLn(Self, TGrammarNode_GetNonTermRuleName(Self^.FGrammar,
      ParseTree^.RuleId));
    TAstViewer_Indent(Self);
    If ParseTree^.Children^.Size > 0 Then
    Begin
      For I := 0 To ParseTree^.Children^.Size - 1 Do
      Begin
        TAstViewer_PrintParseTree(Self, PParseTree(TList_Get(ParseTree^.Children, I)^));
      End;
    End;
    TAstViewer_Deindent(Self);
  End;
End;

Procedure TAstViewer_OutputParseTree(Self: PAstViewer; Path: String);
Var
  mFile: PStream;
  I: TSize;
  mName: PChar;
Begin
  TBinaryFileStream_Create(PBinaryFileStream(Self^.FTreeFile), Path + 'ast.xt');
  TBinaryFileStream_Create(PBinaryFileStream(Self^.FStrFile), Path + 'ast.xs');

  TBinaryFileStream_Create(PBinaryFileStream(mFile), Path + 'ast.xnr');
  For I := 0 To Pred(Self^.FGrammar^.NonTermRuleNames^.Size) Do
  Begin
    mName := PChar(TList_Get(Self^.FGrammar^.NonTermRuleNames, I)^);
    TBinaryFileStream_Write(mFile, mName^, Succ(StrLen(mName)) * SizeOf(Char));
  End;
  mFile^.VMT^.Destroy(mFile);
  Dispose(mFile);

  TBinaryFileStream_Create(PBinaryFileStream(mFile), Path + 'ast.xtr');
  For I := 0 To Pred(Self^.FGrammar^.TermRuleNames^.Size) Do
  Begin
    mName := PChar(TList_Get(Self^.FGrammar^.TermRuleNames, I)^);
    TBinaryFileStream_Write(mFile, mName^, Succ(StrLen(mName)) * SizeOf(Char));
  End;
  mFile^.VMT^.Destroy(mFile);
  Dispose(mFile);

  Self^.FTreeOffset := 0;
  Self^.FStrOffset := 0;

  TAstViewer_DoOuputNode(Self, Self^.FParseTree, SizeOf(TSize));

  Self^.FTreeFile^.VMT^.Destroy(Self^.FTreeFile);
  Self^.FStrFile^.VMT^.Destroy(Self^.FStrFile);
  Dispose(Self^.FTreeFile);
  Dispose(Self^.FStrFile);
End;

Procedure TAstViewer_DoOuputNode(Self: PAstViewer; ParseTree: PParseTree; Parent: TSize);
Var
  mStrLength: TSize;
  mStrSize: TSize;
  I: TSize;
Begin
  TBinaryFileStream_Write(Self^.FTreeFile, Parent, SizeOf(TSize));
  TBinaryFileStream_Write(Self^.FTreeFile, ParseTree^.RuleId, SizeOf(TNonTermRuleId));
  TBinaryFileStream_Write(Self^.FTreeFile, PTermRule(ParseTree^.Token.Kind)^,
    SizeOf(TTermRule));
  TBinaryFileStream_Write(Self^.FTreeFile, ParseTree^.Token.StartPos, SizeOf(TSize));
  TBinaryFileStream_Write(Self^.FTreeFile, Self^.FStrOffset, SizeOf(TSize));
{
  Writeln('Parent=', Parent, ', ParseTree^.RuleId=', ParseTree^.RuleId,
    ', PTermRule(ParseTree^.Token.Kind)^=', PTermRule(ParseTree^.Token.Kind)^,
    ', ParseTree^.Token.StartPos=', ParseTree^.Token.StartPos,
    ', Self^.FStrOffset=', Self^.FStrOffset);
}
  mStrLength := StrLen(ParseTree^.Token.Value);
  mStrSize := SizeOf(Char) * mStrLength;
  TBinaryFileStream_Write(Self^.FStrFile, ParseTree^.Token.Value^, mStrSize);
  Inc(Self^.FStrOffset, mStrLength);

  Parent := Self^.FTreeOffset;
  Inc(Self^.FTreeOffset);

  If (ParseTree^.Children <> nil) And (ParseTree^.Children^.Size > 0) Then
  Begin
    For I := 0 To ParseTree^.Children^.Size - 1 Do
    Begin
      TAstViewer_DoOuputNode(Self, PParseTree(TList_Get(ParseTree^.Children, I)^),
        Parent);
    End;
  End;
End;

Procedure TAstViewer_WriteLn(Self: PAstViewer; Content: PChar);
Var
  I: TSize;
Begin
  If Self^.Level > 0 Then
  Begin
    For I := 0 To Self^.Level - 1 Do
    Begin
      Write('  ');
    End;
  End;
  Writeln(Content);
End;

Procedure TAstViewer_Indent(Self: PAstViewer);
Begin
  Inc(Self^.Level);
End;

Procedure TAstViewer_Deindent(Self: PAstViewer);
Begin
  Dec(Self^.Level);
End;

Function TAstViewer_Term(Parser: PParser; TokenKind: TTermRule): Boolean;
Begin
  Result := TParser_Term(Parser, @TokenKind);
End;

Begin
  mTAstViewer_VMT.Destroy := TAstViewer_Destroy;
  mTAstViewer_VMT.IsTokenKindUndefined := TAstViewer_IsTokenKindUndefined;
  mTAstViewer_VMT.IsTokenKindEof := TAstViewer_IsTokenKindEof;
  mTAstViewer_VMT.CopyTokenKind := TAstViewer_CopyTokenKind;
  mTAstViewer_VMT.CompareTokenKind := TAstViewer_CompareTokenKind;

  mTAstViewer_Methods.VisitId := TAstViewer_VisitId;
  mTAstViewer_Methods.VisitTerm := TAstViewer_VisitTerm;
  mTAstViewer_Methods.VisitGroup := TAstViewer_VisitGroup;
  mTAstViewer_Methods.VisitRule := TAstViewer_VisitRule;
  mTAstViewer_Methods.VisitTermRule := TAstViewer_VisitTermRule;
  mTAstViewer_Methods.VisitGrammar := TAstViewer_VisitGrammar;
End.
