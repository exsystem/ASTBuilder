Unit TermExprRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function TermExprRule(Parser: PParser; Var Ast: PAstNode): Boolean;

Function TermExprRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, List, IdNode, TermNode, GroupNode, TermFactorRuleUnit;

// termExpr -> termFactor* ( Or termFactor* )*
Function TermExprRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS1, mSavePointS2: TSize;
  mFactorNode: PAstNode;
  mGroupNode1, mGroupNodeN: PAstNode;
  mExprNode: PAstNode;
Label
  S1, S2;
Begin
  mGroupNode1 := nil;
  mExprNode := nil;
  Ast := nil;
  mGroupNodeN := nil;
  S1:
    mSavePointS1 := Parser.FCurrentToken;
  If TermFactorRule(Parser, mFactorNode) Then
  Begin
    If mGroupNode1 = nil Then
    Begin
      TGroupNode_Create(PGroupNode(mGroupNode1));
      PGroupNode(mGroupNode1).IsAlternational := False;
      PGroupNode(mGroupNode1).GroupType := TGroupType.eGroup;
      TList_PushBack(PGroupNode(mGroupNode1).Terms, @mFactorNode);
      Ast := mGroupNode1;
    End
    Else
    Begin
      TList_PushBack(PGroupNode(mGroupNode1).Terms, @mFactorNode);
    End;
    Goto S1;
  End
  Else If TParser_Term(Parser, TTokenKind.eOr) Then
  Begin
    If mExprNode = nil Then
    Begin
      TGroupNode_Create(PGroupNode(mExprNode));
      PGroupNode(mExprNode).IsAlternational := True;
      PGroupNode(mExprNode).GroupType := TGroupType.eGroup;
      TList_PushBack(PGroupNode(mExprNode).Terms, @mGroupNode1);
    End
    Else
    Begin
      Ast := mExprNode;
    End;
  End
  Else
  Begin
    Parser.FCurrentToken := mSavePointS1;
    Result := True;
    Exit;
  End;
  S2:
    mSavePointS2 := Parser.FCurrentToken;
  If TermFactorRule(Parser, mFactorNode) Then
  Begin
    If mGroupNodeN = nil Then
    Begin
      TGroupNode_Create(PGroupNode(mGroupNodeN));
      PGroupNode(mGroupNodeN).IsAlternational := False;
      PGroupNode(mGroupNodeN).GroupType := TGroupType.eGroup;
      TList_PushBack(PGroupNode(mGroupNodeN).Terms, @mFactorNode);
    End
    Else
    Begin
      TList_PushBack(PGroupNode(mGroupNodeN).Terms, @mFactorNode);
    End;
    Goto S2;
  End
  Else If TParser_Term(Parser, TTokenKind.eOr) Then
  Begin
    TList_PushBack(PGroupNode(mExprNode).Terms, @mGroupNodeN);
    mGroupNodeN := nil;
    Goto S2;
  End
  Else
  Begin
    If mExprNode <> nil Then
    Begin
      TList_PushBack(PGroupNode(mExprNode).Terms, @mGroupNodeN);
      Ast := mExprNode;
    End;
    Parser.FCurrentToken := mSavePointS2;
    Result := True;
  End;
End;

Function TermExprRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := TermExprRuleExpression1(Parser, Ast);
End;

End.
