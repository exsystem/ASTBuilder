Unit ExprRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function ExprRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Function ExprExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;

Implementation

Uses
  FactorRuleUnit, TypeDef, BinaryOpNode;

Function ExprRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := TParser_Prod(Parser, Ast, [@ExprExpression1]);
  //Result := ExprExpression1(Parser, Ast);
End;

// Expr -> Factor ( opExpr Factor )*
Function ExprExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Var
  mSavePoint: TSize;
  mHeadNode: PAstNode;
  mHeadNodeData: PBinaryOpNode;
  mCurrNode: PAstNode;
  mCurrNodeData: PBinaryOpNode;
  mNewNode: PAstNode;
  mNewNodeData: PBinaryOpNode;
  mResult: Boolean;
Begin
  mHeadNode := TBinaryOpNode_Create();
  mHeadNodeData := PBinaryOpNode(mHeadNode.Data);
  mCurrNode := mHeadNode;
  mCurrNodeData := mHeadNodeData;

  Result := FactorRuleUnit.FactorRule(Parser, mCurrNodeData.RightNode);
  If Result = False Then
  Begin
    TAstNode_Destroy(mHeadNode);
    Exit;
  End;
  // the loop: ( opExpr Factor ) * 
  While Not TParser_Term(Parser, TTokenKind.eEof) Do
  Begin
    mNewNode := TBinaryOpNode_Create();
    mNewNodeData := PBinaryOpNode(mNewNode.Data);

    mSavePoint := Parser.FCurrentToken;
    mResult := False;
    If TParser_Term(Parser, TTokenKind.eAdd) Then
    Begin
      mNewNodeData.OpType := TOpType.ePlus;
      mResult := True;
    End
    Else If TParser_Term(Parser, TTokenKind.eSub) Then
    Begin
      mNewNodeData.OpType := TOpType.eMinus;
      mResult := True;
    End;
    mResult := mResult And FactorRuleUnit.FactorRule(Parser, mNewNodeData.RightNode);
    If Not mResult Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      TAstNode_Destroy(mNewNode);
      Break;
    End;

    mNewNodeData.LeftNode := mCurrNodeData.RightNode;
    mCurrNodeData.RightNode := mNewNode;
    mCurrNode := mNewNode;
  End;

  Ast := mHeadNodeData.RightNode;
  mHeadNodeData.RightNode := nil;
  TAstNode_Destroy(mHeadNode);
End;

End.
