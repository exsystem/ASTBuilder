{ Unit GrammarNode; }
Unit GrmrNode;

{$I define.inc}

Interface

Uses
  ASTNode, TRMRNODE, List, Trie, TypeDef, RuleNode;

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
    NonTermRuleNames: PList; { Of PChar }
    NonTermRuleIds: PTrie; { Of TNonTermRule }
    { <mode, rules[]>[] }
    TermRules: PTrie; { Of PList<PTermRuleNode> }
    TermRuleNames: PList; { Of PChar }
    TermRuleIds: PTrie; { Of TTermRule }
    TermRulesCount: TSize;
  End;

Procedure TGrammarNode_Create(Var Self: PGrammarNode);
Procedure TGrammarNode_Destroy(Self: PAstNode);
Procedure TGrammarNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Function TGrammarNode_GetNonTermRuleId(Self: PGrammarNode;
  Const Name: PChar): TNonTermRuleId;
Function TGrammarNode_GetNonTermRuleName(Self: PGrammarNode;
  Const Id: TNonTermRuleId): PChar;
Function TGrammarNode_RegisterNonTermRule(Self: PGrammarNode;
  Name: PChar): TNonTermRuleId;
Procedure TGrammarNode_AddTermRule(Self: PGrammarNode; Mode: PChar;
  TermRuleNode: PTermRuleNode);
Function TGrammarNode_GetTermRuleId(Self: PGrammarNode; Const Name: PChar): TTermRule;
Function TGrammarNode_GetTermRuleName(Self: PGrammarNode; Const Id: TTermRule): PChar;
Function TGrammarNode_RegisterTermRule(Self: PGrammarNode; Name: PChar): TTermRule;

Var
  mTGrammarNode_VMT: TAstNode_VMT;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

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
Var
  mName: PChar;
  mId0, mId1: TTermRule;
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self^.Parent.VMT := @mTGrammarNode_VMT;

  Self^.Options[COption_CaseInsensitive].BooleanValue := False;

  Self^.Rules := TList_Create(SizeOf(PRuleNode), 1);
  Self^.NonTermRuleNames := TList_Create(SizeOf(PChar), 2);
  Self^.NonTermRuleIds := TTrie_Create(SizeOf(PNonTermRuleId), nil);
  mName := StrNew('');
  mId0 := 0;
  TList_PushBack(Self^.NonTermRuleNames, @mName);
  TTrie_Set(Self^.NonTermRuleIds, mName, @mId0);
  mName := StrNew('*');
  mId1 := 1;
  TList_PushBack(Self^.NonTermRuleNames, @mName);
  TTrie_Set(Self^.NonTermRuleIds, mName, @mId1);

  Self^.TermRules := TTrie_Create(SizeOf(PList), TermRulesElementDestructor);
  Self^.TermRuleNames := TList_Create(SizeOf(PChar), 2);
  Self^.TermRuleIds := TTrie_Create(SizeOf(TTermRule), nil);
  mName := StrNew('');
  mId0 := 0;
  TList_PushBack(Self^.TermRuleNames, @mName);
  TTrie_Set(Self^.TermRuleIds, mName, @mId0);
  mName := StrNew('EOF');
  mId1 := 1;
  TList_PushBack(Self^.TermRuleNames, @mName);
  TTrie_Set(Self^.TermRuleIds, mName, @mId1);
End;

Procedure TGrammarNode_Destroy(Self: PAstNode);
Var
  I: TSize;
  mElem: PAstNode;
  mName: PChar;
Begin
  If PGrammarNode(Self)^.NonTermRuleNames^.Size > 0 Then
  Begin
    For I := 0 To PGrammarNode(Self)^.NonTermRuleNames^.Size - 1 Do
    Begin
      mName := PPChar(TList_Get(PGrammarNode(Self)^.NonTermRuleNames, I))^;
      FreeStr(mName);
    End;
  End;
  TList_Destroy(PGrammarNode(Self)^.NonTermRuleNames);
  TTrie_Destroy(PGrammarNode(Self)^.NonTermRuleIds);
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

  If PGrammarNode(Self)^.TermRuleNames^.Size > 0 Then
  Begin
    For I := 0 To PGrammarNode(Self)^.TermRuleNames^.Size - 1 Do
    Begin
      mName := PPChar(TList_Get(PGrammarNode(Self)^.TermRuleNames, I))^;
      FreeStr(mName);
    End;
  End;
  TList_Destroy(PGrammarNode(Self)^.TermRuleNames);
  TTrie_Destroy(PGrammarNode(Self)^.TermRuleIds);
  TTrie_Destroy(PGrammarNode(Self)^.TermRules);

  TAstNode_Destroy(Self);
End;

Procedure TGrammarNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  PGrammarNode(Self)^.TermRulesCount := PGrammarNode(Self)^.TermRuleNames.Size;
  Visitor^.Methods^.VisitGrammar(Visitor, Self);
End;

Function TGrammarNode_GetNonTermRuleId(Self: PGrammarNode;
  Const Name: PChar): TNonTermRuleId;
Begin
  Result := PNonTermRuleId(TTrie_Get(Self^.NonTermRuleIds, Name))^;
End;

Function TGrammarNode_GetNonTermRuleName(Self: PGrammarNode;
  Const Id: TNonTermRuleId): PChar;
Begin
  Result := PChar(TList_Get(Self^.NonTermRuleNames, Id)^);
End;

Function TGrammarNode_RegisterNonTermRule(Self: PGrammarNode;
  Name: PChar): TNonTermRuleId;
Var
  mName: PChar;
Begin
  mName := StrNew(Name);
  Result := Self^.NonTermRuleNames^.Size;
  TList_PushBack(Self^.NonTermRuleNames, @mName);
  TTrie_Set(Self^.NonTermRuleIds, Name, @Result);
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

Function TGrammarNode_GetTermRuleId(Self: PGrammarNode; Const Name: PChar): TTermRule;
Begin
  Result := PTermRule(TTrie_Get(Self^.TermRuleIds, Name))^;
End;

Function TGrammarNode_GetTermRuleName(Self: PGrammarNode; Const Id: TTermRule): PChar;
Begin
  Result := PChar(TList_Get(Self^.TermRuleNames, Id)^);
End;

Function TGrammarNode_RegisterTermRule(Self: PGrammarNode; Name: PChar): TTermRule;
Var
  mName: PChar;
Begin
  mName := StrNew(Name);
  Result := Self^.TermRuleNames^.Size;
  TList_PushBack(Self^.TermRuleNames, @mName);
  TTrie_Set(Self^.TermRuleIds, Name, @Result);
End;

Begin
  mTGrammarNode_VMT.Destory := TGrammarNode_Destroy;
  mTGrammarNode_VMT.Accept := TGrammarNode_Accept;
End.
