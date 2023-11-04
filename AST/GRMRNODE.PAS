{ Unit GrammarNode; }
Unit GrmrNode;

{$I define.inc}

Interface

Uses
  ASTNode, TRMRNODE, List, Trie;

Const
  COption_CaseInsensitive = Byte($00);
  COption_End = Byte($FF);

Type
  TOptionValue = Record
    Case Integer Of
      0: (BooleanValue: Boolean);
      1: (StringValue: PChar);
  End;

  TOptions = Array[COption_CaseInsensitive..COption_End] Of TOptionValue;

  PGrammarNode = ^TGrammarNode;

  TGrammarNode = Record
    Parent: TAstNode;
    Options: TOptions;
    Rules: PList; { Of PRuleNode }
    TermRules: PTrie; { Of PList<PTermRuleNode> }
  End;

Procedure TGrammarNode_Create(Var Self: PGrammarNode);
Procedure TGrammarNode_Destroy(Self: PAstNode);
Procedure TGrammarNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Procedure TGrammarNode_AddTermRule(Self: PGrammarNode; Mode: PChar;
  TermRuleNode: PTermRuleNode);

Var
  mTGrammarNode_VMT: TAstNode_VMT;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil, TypeDef, RuleNode;

Procedure TermRulesElementDestructor(Const Element: Pointer);
Var
  I: TSize;
  mElem: PAstNode;
  mList: PList;
Begin
  mList := PList(Element^);
  If mList^.Size > 0 Then
  Begin
    For I := 0 To mList^.Size - 1 Do
    Begin
      mElem := PPAstNode(TList_Get(mList, I))^;
      mElem^.VMT^.Destory(mElem);
      Dispose(mElem);
    End;
  End;
  TList_Destroy(mList);
End;

Procedure TGrammarNode_Create(Var Self: PGrammarNode);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self^.Parent.VMT := @mTGrammarNode_VMT;

  Self^.Options[COption_CaseInsensitive].BooleanValue := False;
  Self^.Rules := TList_Create(SizeOf(PRuleNode), 1);
  Self^.TermRules := TTrie_Create(SizeOf(PList), TermRulesElementDestructor);
End;

Procedure TGrammarNode_Destroy(Self: PAstNode);
Var
  I: TSize;
  mElem: PAstNode;
Begin
  If PGrammarNode(Self)^.Rules^.Size > 0 Then
  Begin
    For I := 0 To PGrammarNode(Self)^.Rules^.Size - 1 Do
    Begin
      mElem := PPAstNode(TList_Get(PGrammarNode(Self)^.Rules, I))^;
      mElem^.VMT^.Destory(mElem);
      Dispose(mElem);
    End;
  End;
  TList_Destroy(PGrammarNode(Self)^.Rules);
  TTrie_Destroy(PGrammarNode(Self)^.TermRules);
  TAstNode_Destroy(Self);
End;

Procedure TGrammarNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor^.Methods^.VisitGrammar(Visitor, Self);
End;

Procedure TGrammarNode_AddTermRule(Self: PGrammarNode; Mode: PChar;
  TermRuleNode: PTermRuleNode);
Var
  mPElem: PPList;
  mElem: PList;
Begin
  mPElem := PPList(TTrie_Get(Self^.TermRules, Mode));
  If mPElem = nil Then
  Begin
    mElem := TList_Create(SizeOf(PTermRuleNode), 1);
    TTrie_Set(Self^.TermRules, Mode, @mElem);
  End
  Else
  Begin
    mElem := mPElem^;
  End;
  TList_PushBack(mElem, @TermRuleNode);
End;

Begin
  mTGrammarNode_VMT.Destory := TGrammarNode_Destroy;
  mTGrammarNode_VMT.Accept := TGrammarNode_Accept;
End.
