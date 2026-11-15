{ Unit GrammarViewer; }
Unit GrmrViwr;


{$I define.inc}

Interface

Uses
  ASTNode, GrmrNode, TypeDef;

Type
  PAstViewer = ^TAstViewer;

  TAstViewer = Record
    As_IAstVisitor: PAstVisitor;
    Level: TSize;
    GrammarNode: PGrammarNode;
  End;

Procedure TAstViewer_Create(Var Self: PAstViewer);

Procedure TAstViewer_Destroy(Self: PAstViewer);

Procedure TAstViewer_VisitId(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitTerm(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitGroup(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitRule(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitTermRule(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_VisitGrammar(Intf: PAstVisitor; Node: PAstNode);

Procedure TAstViewer_WriteLn(Self: PAstViewer; Content: PTChar); Overload;
Procedure TAstViewer_WriteLn(Self: PAstViewer; Const Content: AnsiString); Overload;

Procedure TAstViewer_Indent(Self: PAstViewer);

Procedure TAstViewer_Deindent(Self: PAstViewer);

Implementation

Uses
  List, Trie, IdNode, TrmNode, GrpNode, RuleNode, TrmRNode, NFA,
  SysUtils{$IFDEF USE_STRINGS}, strings{$ENDIF}, {$IFDEF VINTAGE} Utility,{$ENDIF} StrUtil;

Var
  mTAstViewer_Methods: TAstVisitor_Methods;

Procedure TAstViewer_Create(Var Self: PAstViewer);
Begin
  New(Self); { Final }
  New(Self^.As_IAstVisitor);
  Self^.As_IAstVisitor^.Instance := Self;
  Self^.As_IAstVisitor^.Methods := @mTAstViewer_Methods;

  Self^.Level := 0;
End;

Procedure TAstViewer_Destroy(Self: PAstViewer);
Begin
  Dispose(Self^.As_IAstVisitor);
End;

Procedure TAstViewer_VisitId(Intf: PAstVisitor; Node: PAstNode);
Var
  mNode: PIdNode;
  mText: PTChar;
Begin
  mNode := PIdNode(Node);
  mText := TCharStrNew('Non-Terminal: ');
  mText := ReallocStr(mText, TCharStrLen(mText) + TCharStrLen(mNode^.Value));
  TCharStrCat(mText, mNode^.Value);
  TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mText);
  FreeStr(mText);
End;

Procedure TAstViewer_VisitTerm(Intf: PAstVisitor; Node: PAstNode);
Var
  mNode: PTermNode;
  mText: PTChar;
Begin
  mNode := PTermNode(Node);
  mText := TCharStrNew('Terminal: ');
  mText := ReallocStr(mText, TCharStrLen(mText) + TCharStrLen(mNode^.Token.Value));
  TCharStrCat(mText, mNode^.Token.Value);
  TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mText);
  FreeStr(mText);
End;

Procedure TAstViewer_VisitGroup(Intf: PAstVisitor; Node: PAstNode);
Var
  mNode: PGroupNode;
  I: TSize;
  mItem: PAstNode;
  mGroupType: AnsiString;
  mTermsRelationship: AnsiString;
  mText: PTChar;
Begin
  mNode := PGroupNode(Node);
  Case mNode^.GroupType Of
    eGroup:
      mGroupType := 'Group';
    eOneOrMore:
      mGroupType := 'OneOrMore';
    eOptional:
      mGroupType := 'Optional';
    eMultiple:
      mGroupType := 'Multiple';
  End;
  If mNode^.IsAlternational Then
  Begin
    mTermsRelationship := ' Alternation';
  End
  Else
  Begin
    mTermsRelationship := '';
  End;

  mText := TCharStrNew(mGroupType);
  mText := ReallocStr(mText, TCharStrLen(mText) + Length(mTermsRelationship) +
    Length(':'));
  TCharStrCat(mText, mTermsRelationship);
  TCharStrCat(mText, ':');
  TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mText);
  FreeStr(mText);

  For I := 0 To mNode^.Terms^.Size - 1 Do
  Begin
    mItem := PPAstNode(TList_Get(mNode^.Terms, I))^;
    TAstViewer_Indent(PAstViewer(Intf^.Instance));
    If mItem = nil Then
    Begin
      TAstViewer_WriteLn(PAstViewer(Intf^.Instance), '<empty term>');
    End
    Else
    Begin
      mItem^.VMT^.Accept(mItem, Intf);
    End;
    TAstViewer_Deindent(PAstViewer(Intf^.Instance));
  End;
End;

Procedure TAstViewer_VisitRule(Intf: PAstVisitor; Node: PAstNode);
Var
  mNode: PRuleNode;
  mText: PTChar;
Begin
  mNode := PRuleNode(Node);
  mText := PPTChar(TList_Get(PAstViewer(Intf^.Instance)^.GrammarNode^.NonTermRuleNames,
    mNode^.Id))^;
  mText := ReallocStr(mText, TCharStrLen(mText) + Length(':'));
  TCharStrCat(mText, ':');
  TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mText);
  FreeStr(mText);
  TAstViewer_Indent(PAstViewer(Intf^.Instance));
  If mNode^.Expr = nil Then
  Begin
    TAstViewer_WriteLn(PAstViewer(Intf^.Instance), '<empty syntax rule>');
  End
  Else
  Begin
    mNode^.Expr^.Parent.VMT^.Accept(PAstNode(mNode^.Expr), Intf);
  End;
  TAstViewer_Deindent(PAstViewer(Intf^.Instance));
End;

Procedure TAstViewer_VisitTermRule(Intf: PAstVisitor; Node: PAstNode);
Var
  mNode: PTermRuleNode;
  mState: PNfaState;
  mEdge: PNfaEdge;
  I, J: TSize;
  mFromState: AnsiString;
  mText: PTChar;
  mStr: AnsiString;
  mStrPChar: PTChar;
  mCommand: PCommand;
  mName: PTChar;
Begin
  mNode := PTermRuleNode(Node);
  mName := PPTChar(TList_Get(PAstViewer(Intf^.Instance)^.GrammarNode^.TermRuleNames,
    mNode^.TermRuleId))^;
  mText := CreateStr(TCharStrLen(mName) + Length(':'));
  TCharStrCat(mText, mName);
  TCharStrCat(mText, ':');
  TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mText);
  FreeStr(mText);
  TAstViewer_Indent(PAstViewer(Intf^.Instance));
  If mNode^.Nfa = nil Then
  Begin
    TAstViewer_WriteLn(PAstViewer(Intf^.Instance), '<empty lex rule>');
  End
  Else
  Begin
    If Not TList_IsEmpty(mNode^.CommandList) Then
    Begin
      For J := 0 To Pred(mNode^.CommandList^.Size) Do
      Begin
        mCommand := PCommand(TList_Get(mNode^.CommandList, J));
        Case mCommand^.CommandType Of
          eSkipCommand:
          Begin
            TAstViewer_WriteLn(PAstViewer(Intf^.Instance), 'Ignored');
          End;
          ePushModeCommand:
          Begin
            TAstViewer_WriteLn(PAstViewer(Intf^.Instance), 'Push Mode:');
            TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mCommand^.Arg);
          End;
          ePopModeCommand:
          Begin
            TAstViewer_WriteLn(PAstViewer(Intf^.Instance), 'Pop Mode');
          End;
        End;
      End;
    End;
    mStr := IntToStr(mNode^.Nfa^.StartState);
    mStrPChar := TCharStrNew(mStr);
    mText := CreateStr(Length('Keyword: ') + TCharStrLen(mNode^.Nfa^.Keyword));
    TCharStrCat(mText, 'Keyword: ');
    TCharStrCat(mText, mNode^.Nfa^.Keyword);
    TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mText);
    FreeStr(mText);
    mText := CreateStr(Length('Start state: ') + TCharStrLen(mStrPChar));
    TCharStrCat(mText, 'Start state: ');
    TCharStrCat(mText, mStrPChar);
    FreeStr(mStrPChar);
    TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mText);
    FreeStr(mText);
    TAstViewer_WriteLn(PAstViewer(Intf^.Instance), 'Moves: ');
    TAstViewer_Indent(PAstViewer(Intf^.Instance));
    TAstViewer_WriteLn(PAstViewer(Intf^.Instance), '```mermaid');
    TAstViewer_WriteLn(PAstViewer(Intf^.Instance), 'graph LR');
    For I := 0 To mNode^.Nfa^.States^.Size - 1 Do
    Begin
      mState := TNfa_GetState(mNode^.Nfa, I);
      If mState^.Acceptable Then
      Begin
        mFromState := IntToStr(I) + '[[' + IntToStr(I) + ': Acceptable]]';
      End
      Else
      Begin
        mFromState := IntToStr(I);
      End;
      TAstViewer_Indent(PAstViewer(Intf^.Instance));
      If mState^.Edges^.Size > 0 Then
      Begin
        For J := 0 To mState^.Edges^.Size - 1 Do
        Begin
          mEdge := PNfaEdge(TList_Get(mState^.Edges, J));
          mStr := TCharStrToAnsiString(mEdge^.Value);
          If mStr = '' Then
          Begin
            mStr := mFromState + ' -->| |' + IntToStr(mEdge^.ToState) + ';' + #0;
          End
          Else
          Begin
            mStr := mFromState + ' -->|' + TCharStrToAnsiString(mEdge^.Value) +
              ' |' + IntToStr(mEdge^.ToState) + ';' + #0;
          End;
          mText := TCharStrNew(mStr);
          TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mText);
          FreeStr(mText);
        End;
      End
      Else
      Begin
        mStr := mFromState + ';' + #0;
        mText := TCharStrNew(mStr);
        TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mText);
        FreeStr(mText);
      End;
      TAstViewer_Deindent(PAstViewer(Intf^.Instance));
    End;
    TAstViewer_WriteLn(PAstViewer(Intf^.Instance), '```');
    TAstViewer_Deindent(PAstViewer(Intf^.Instance));
  End;
  TAstViewer_Deindent(PAstViewer(Intf^.Instance));
End;

Procedure TAstViewer_VisitGrammar(Intf: PAstVisitor; Node: PAstNode);
Var
  mNode: PGrammarNode;
  I: TSize;
  mItem: PAstNode;
  mIterator, mEndIterator: PTrieIterator;
  mList: PList;
  mText: PTChar;
  mStr: AnsiString;
  mMode: PTChar;
Begin
  mNode := PGrammarNode(Node);
  PAstViewer(Intf^.Instance)^.GrammarNode := mNode;

  TAstViewer_WriteLn(PAstViewer(Intf^.Instance), 'Options:');
  TAstViewer_Indent(PAstViewer(Intf^.Instance));
  If mNode^.Options[COption_CaseInsensitive].BooleanValue Then
  Begin
    TAstViewer_WriteLn(PAstViewer(Intf^.Instance), 'CaseInsensitive;');
  End;
  TAstViewer_Deindent(PAstViewer(Intf^.Instance));

  TAstViewer_WriteLn(PAstViewer(Intf^.Instance), 'Grammar (Non-Term Rules):');
  TAstViewer_Indent(PAstViewer(Intf^.Instance));
  If mNode^.Rules^.Size <> 0 Then
  Begin
    For I := 0 To mNode^.Rules^.Size - 1 Do
    Begin
      mItem := PPAstNode(TList_Get(mNode^.Rules, I))^;
      TAstViewer_Indent(PAstViewer(Intf^.Instance));
      mItem^.VMT^.Accept(mItem, Intf);
      TAstViewer_Deindent(PAstViewer(Intf^.Instance));
    End;
  End;
  TAstViewer_Deindent(PAstViewer(Intf^.Instance));

  TAstViewer_WriteLn(PAstViewer(Intf^.Instance), 'Grammar (Term Rules):');
  TAstViewer_Indent(PAstViewer(Intf^.Instance));
  mIterator := TTrie_Begin(mNode^.TermRules);
  mEndIterator := TTrie_End(mNode^.TermRules);
  While Not CompareMem(@(mIterator^.FCurrent), @(mEndIterator^.FCurrent),
      SizeOf(TSuffixNodePair)) Do
  Begin
    GetMem(mMode, mIterator^.FCurrent.SuffixSize + SizeOf(TChar));
    Move(mIterator^.FCurrent.Suffix^, mMode^, mIterator^.FCurrent.SuffixSize);
    PByte(mMode)[mIterator^.FCurrent.SuffixSize] := 0;
    mStr := TCharStrToAnsiString(mMode);
    FreeMem(mMode, mIterator^.FCurrent.SuffixSize + SizeOf(TChar));
    mStr := 'Mode [' + mStr + ']';
    mText := TCharStrNew(mStr);
    TAstViewer_WriteLn(PAstViewer(Intf^.Instance), mText);
    FreeStr(mText);
    TAstViewer_Indent(PAstViewer(Intf^.Instance));
    mList := PList(mIterator^.FCurrent.Node^.Data^);
    If mList^.Size <> 0 Then
    Begin
      For I := 0 To mList^.Size - 1 Do
      Begin
        mItem := PPAstNode(TList_Get(mList, I))^;
        TAstViewer_Indent(PAstViewer(Intf^.Instance));
        mItem^.VMT^.Accept(mItem, Intf);
        TAstViewer_Deindent(PAstViewer(Intf^.Instance));
      End;
    End;
    TAstViewer_Deindent(PAstViewer(Intf^.Instance));
    TTrieIterator_Next(mIterator);
  End;
  TTrieIterator_Destroy(mIterator);
  Dispose(mIterator);
End;

Procedure TAstViewer_WriteLn(Self: PAstViewer; Content: PTChar);
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
  Writeln(TCharStrToAnsiString(Content));
End;

Procedure TAstViewer_WriteLn(Self: PAstViewer; Const Content: AnsiString);
Var
  mText: PTChar;
Begin
  mText := TCharStrNew(Content);
  TAstViewer_WriteLn(Self, mText);
  FreeStr(mText);
End;

Procedure TAstViewer_Indent(Self: PAstViewer);
Begin
  Inc(Self^.Level);
End;

Procedure TAstViewer_Deindent(Self: PAstViewer);
Begin
  Dec(Self^.Level);
End;

Begin
  mTAstViewer_Methods.VisitId := TAstViewer_VisitId;
  mTAstViewer_Methods.VisitTerm := TAstViewer_VisitTerm;
  mTAstViewer_Methods.VisitGroup := TAstViewer_VisitGroup;
  mTAstViewer_Methods.VisitRule := TAstViewer_VisitRule;
  mTAstViewer_Methods.VisitTermRule := TAstViewer_VisitTermRule;
  mTAstViewer_Methods.VisitGrammar := TAstViewer_VisitGrammar;
End.
