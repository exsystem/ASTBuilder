Unit ExprRule;

{$MODE DELPHI}

Interface

Uses
  Parser, Lexer, ASTNode;

Function ExprRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Function ExprExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;

Implementation

Uses
  FactorRule, TypeDef, BinaryOpNode;

Function ExprRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := ExprExpression1(Parser, Ast);
End;

// Expr -> Factor ( opExpr Factor )*
Function ExprExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Var
  mTemp: TSize;
  mHeadNode: PAstNode;
  mHeadNodeData: PBinaryOpNode;
  mCurrNode: PAstNode;
  mCurrNodeData: PBinaryOpNode;
  mNewNode: PAstNode;
  mNewNodeData: PBinaryOpNode;
Begin
  mHeadNode := TBinaryOpNode_Create();
  mHeadNodeData := PBinaryOpNode(mHeadNode.Data);
  mCurrNode := mHeadNode;
  mCurrNodeData := mHeadNodeData;

  Result := FactorRule.FactorRule(Parser, mCurrNodeData.RightNode);
  If Result = False Then
  Begin
    TAstNode_Destroy(mHeadNode);
    Exit;
  End;
  // the loop: ( opExpr Factor ) * 
  While Not TParser_MatchNextToken(Parser, TTokenKind.eEof) Do
  Begin
    mNewNode := TBinaryOpNode_Create();
    mNewNodeData := PBinaryOpNode(mNewNode.Data);

    mTemp := Parser.FCurrentToken;
    If TParser_MatchNextToken(Parser, TTokenKind.eAdd) Then
    Begin
      mNewNodeData.OpType := TOpType.ePlus;
      Result := True;
    End
    Else If TParser_MatchNextToken(Parser, TTokenKind.eSub) Then
    Begin
      mNewNodeData.OpType := TOpType.eMinus;
      Result := True;
    End;
    // Mark the position as a new term of 'opExpr Factor' begins, for fallback purpose if parsing fails.
    Result := Result And FactorRule.FactorRule(Parser, mNewNodeData.RightNode);
    If Not Result Then
    Begin
      Parser.FCurrentToken := mTemp; // Fallback to the marked position.
      Result := True;
      TAstNode_Destroy(mNewNode);
      Break;
    End;

    mNewNodeData.LeftNode := mCurrNodeData.RightNode;
    mCurrNodeData.RightNode := mNewNode;
    mCurrNode := mNewNode;
  End;

  Ast := mHeadNodeData.RightNode;
  mHeadNodeData.RightNode := Nil;
  TAstNode_Destroy(mHeadNode);
End;

End.
