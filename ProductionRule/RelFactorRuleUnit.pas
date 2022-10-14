Unit RelFactorRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function RelFactorRule(Parser: PParser; Out Ast: PAstNode): Boolean;

Function RelFactorExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;

Implementation

Uses
  AddFactorRuleUnit, TypeDef, BinaryOpNode, AddOpRuleUnit;

Function RelFactorRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := RelFactorExpression1(Parser, Ast);
End;

Function RelFactorExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Var
  mSavePoint: TSize;
  mRightNode: PAstNode;
  mHeadNode: PBinaryOpNode;
  mCurrNode: PBinaryOpNode;
  mNewNode: PBinaryOpNode;
Begin
  If Not AddFactorRule(Parser, mRightNode) Then
  Begin
    Parser.Error := 'Additive expression expected.';
    Ast := nil;
    Result := False;
    Exit;
  End;

  New(mHeadNode);
  TBinaryOpNode_Create(mHeadNode);
  mCurrNode := mHeadNode;
  mCurrNode.RightNode := mRightNode;

  Result := True;
  While Not TParser_Term(Parser, eEof) Do
  Begin
    mSavePoint := Parser.FCurrentToken;
    If Not AddOpRule(Parser, PAstNode(mNewNode)) Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      Break;
    End;
    If Not AddFactorRule(Parser, mRightNode) Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      Break;
    End;

    mNewNode.LeftNode := mCurrNode.RightNode;
    mNewNode.RightNode := mRightNode;
    mCurrNode.RightNode := PAstNode(mNewNode);
  End;

  Ast := mHeadNode.RightNode;
  mHeadNode.RightNode := nil;
  TBinaryOpNode_Destroy(PAstNode(mHeadNode));
  Dispose(mHeadNode);
End;

End.
