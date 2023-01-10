Unit ExprRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function ExprRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function ExprRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, List, ClassUtils, IdNode, TermNode, GroupNode, FactorRuleUnit;

// expr -> factor factor* ( Or factor factor* )*
Function ExprRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS2, mSavePointS4: TSize;
  mFactorNode1, mFactorNodeN: PAstNode;
  mGroupNode1, mGroupNodeN: PAstNode;
  mExprNode: PAstNode;
Label
  S1, S2, S3, S4;
Begin
  S1:
    If FactorRule(Parser, mFactorNode1) Then
    Begin
      TGroupNode_Create(PGroupNode(mGroupNode1));
      PGroupNode(mGroupNode1).GroupType := TGroupType.eGroup;
      TList_PushBack(PGroupNode(mGroupNode1).Terms, @mFactorNode1);
      mExprNode := nil;
      Ast := mGroupNode1;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    mSavePointS2 := Parser.FCurrentToken;
  If FactorRule(Parser, mFactorNodeN) Then
  Begin
    TList_PushBack(PGroupNode(mGroupNode1).Terms, @mFactorNodeN);
    Goto S2;
  End
  Else
  If TParser_Term(Parser, TTokenKind.eOr) Then
  Begin
    If mExprNode = nil Then
    Begin
      TGroupNode_Create(PGroupNode(mExprNode));
      PGroupNode(mExprNode).GroupType := TGroupType.eOr;
      TList_PushBack(PGroupNode(mExprNode).Terms, @mGroupNode1);
    End
    Else
    Begin
      Ast := mExprNode;
    End;
  End
  Else
  Begin
    Parser.FCurrentToken := mSavePointS2;
    Result := True;
  End;
  S3:
    If FactorRule(Parser, mFactorNode1) Then
    Begin
      TGroupNode_Create(PGroupNode(mGroupNodeN));
      PGroupNode(mGroupNodeN).GroupType := TGroupType.eGroup;
      TList_PushBack(PGroupNode(mGroupNodeN).Terms, @mFactorNode1);
    End
    Else
    Begin
      Parser.FCurrentToken := mSavePointS2;
      Result := True;
    End;
  S4:
    mSavePointS4 := Parser.FCurrentToken;
  If FactorRule(Parser, mFactorNodeN) Then
  Begin
    TList_PushBack(PGroupNode(mGroupNodeN).Terms, @mFactorNodeN);
    Goto S4;
  End
  Else
  If TParser_Term(Parser, TTokenKind.eOr) Then
  Begin
    TList_PushBack(PGroupNode(mExprNode).Terms, @mGroupNodeN);
    Goto S3;
  End
  Else
  Begin
    Parser.FCurrentToken := mSavePointS4;
    Result := True;
  End;
End;

Function ExprRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := ExprRuleExpression1(Parser, Ast);
End;

End.
