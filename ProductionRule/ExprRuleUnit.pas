Unit ExprRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function ExprRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function ExprExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  FactorRuleUnit, TypeDef, BinaryOpNode;

Function ExprRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  //Result := TParser_Prod(Parser, Ast, [@ExprExpression1]);
  Result := ExprExpression1(Parser, Ast);
End;

// Expr -> Factor ( opExpr Factor )*
Function ExprExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePoint: TSize;
  mHeadNode: PBinaryOpNode;
  mCurrNode: PBinaryOpNode;
  mNewNode: PBinaryOpNode;
  mResult: Boolean;
Begin
  New(mHeadNode);
  TBinaryOpNode_Create(mHeadNode);
  mCurrNode := mHeadNode;

  Result := FactorRuleUnit.FactorRule(Parser, mCurrNode.RightNode);
  If Result = False Then
  Begin
    TBinaryOpNode_Destroy(PAstNode(mHeadNode));
    Dispose(mHeadNode);
    Exit;
  End;
  // the loop: ( opExpr Factor ) * 
  While Not TParser_Term(Parser, eEof) Do
  Begin
    New(mNewNode);
    TBinaryOpNode_Create(mNewNode);

    mSavePoint := Parser.FCurrentToken;
    mResult := False;
    If TParser_Term(Parser, eAdd) Then
    Begin
      mNewNode.OpType := ePlus;
      mResult := True;
    End
    Else If TParser_Term(Parser, eSub) Then
    Begin
      mNewNode.OpType := eMinus;
      mResult := True;
    End;
    mResult := mResult And FactorRuleUnit.FactorRule(Parser, mNewNode.RightNode);
    If Not mResult Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      TBinaryOpNode_Destroy(PAstNode(mNewNode));
      Dispose(mNewNode);
      Break;
    End;

    mNewNode.LeftNode := mCurrNode.RightNode;
    mCurrNode.RightNode := PAstNode(mNewNode);
  End;

  Ast := mHeadNode.RightNode;
  mHeadNode.RightNode := nil;
  TBinaryOpNode_Destroy(PAstNode(mHeadNode));
  Dispose(mHeadNode);
End;

End.
