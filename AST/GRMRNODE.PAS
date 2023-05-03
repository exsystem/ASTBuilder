{ Unit GrammarNode; }
Unit GrmrNode;

{$I define.inc}

Interface

Uses
  ASTNode, List;

Const 
  COption_CaseInsensitive = Byte($00);
  COption_End = Byte($FF);

Type
  TOptionValue = record
    case Integer of
      0: (BooleanValue: Boolean);
      1: (StringValue: PChar);
  end;

  TOptions = Array[COption_CaseInsensitive..COption_End] Of TOptionValue;

  PGrammarNode = ^TGrammarNode;

  TGrammarNode = Record
    Parent: TAstNode;
    Options: TOptions;
    Rules: PList; { Of PRuleNode }
    TermRules: PList; { Of PTermRuleNode }
  End;

Procedure TGrammarNode_Create(Var Self: PGrammarNode);
Procedure TGrammarNode_Destroy(Self: PAstNode);
Procedure TGrammarNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTGrammarNode_VMT: TAstNode_VMT;

Implementation

Uses
  TypeDef, RuleNode, TrmRNode;

Procedure TGrammarNode_Create(Var Self: PGrammarNode);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self^.Parent.VMT := @mTGrammarNode_VMT;

  Self^.Options[COption_CaseInsensitive].BooleanValue := False;
  Self^.Rules := TList_Create(SizeOf(PRuleNode), 1);
  Self^.TermRules := TList_Create(SizeOf(PTermRuleNode), 1);
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
  If PGrammarNode(Self)^.TermRules^.Size > 0 Then
  Begin
    For I := 0 To PGrammarNode(Self)^.TermRules^.Size - 1 Do
    Begin
      mElem := PPAstNode(TList_Get(PGrammarNode(Self)^.TermRules, I))^;
      mElem^.VMT^.Destory(mElem);
      Dispose(mElem);
    End;
  End;
  TList_Destroy(PGrammarNode(Self)^.TermRules);
  TAstNode_Destroy(Self);
End;

Procedure TGrammarNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor^.VMT^.VisitGrammar(Visitor, Self);
End;

Begin
  mTGrammarNode_VMT.Destory := TGrammarNode_Destroy;
  mTGrammarNode_VMT.Accept := TGrammarNode_Accept;
End.
