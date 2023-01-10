Unit GrammarNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode, List;

Type
  PGrammarNode = ^TGrammarNode;

  TGrammarNode = Record
    Parent: TAstNode;
    Rules: PList; // Of PRuleNode 
  End;

Procedure TGrammarNode_Create(Var Self: PGrammarNode);
Procedure TGrammarNode_Destroy(Self: PAstNode);
Procedure TGrammarNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTGrammarNode_VMT: TAstNode_VMT;

Implementation

Uses
  TypeDef;

Procedure TGrammarNode_Create(Var Self: PGrammarNode);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT := @mTGrammarNode_VMT;

  Self.Rules := TList_Create(SizeOf(PAstNode), 1);
End;

Procedure TGrammarNode_Destroy(Self: PAstNode);
Var
  I: TSize;
  mElem: PAstNode;
Begin
  If PGrammarNode(Self).Rules.Size > 0 Then
  Begin
    For I := 0 To PGrammarNode(Self).Rules.Size - 1 Do
    Begin
      mElem := PPAstNode(TList_Get(PGrammarNode(Self).Rules, I))^;
      mElem.VMT.Destory(mElem);
      Dispose(mElem);
    End;
  End;
  TList_Destroy(PGrammarNode(Self).Rules);
  TAstNode_Destroy(Self);
End;

Procedure TGrammarNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitGrammar(Visitor, Self);
End;

Begin
  mTGrammarNode_VMT.Destory := TGrammarNode_Destroy;
  mTGrammarNode_VMT.Accept := TGrammarNode_Accept;
End.
