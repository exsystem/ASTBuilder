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
  RelFactorRuleUnit, TypeDef, BinaryOpNode, RelOpRuleUnit;

Function ExprRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  //Result := TParser_Prod(Parser, Ast, [@ExprExpression1]);
  Result := ExprExpression1(Parser, Ast);
End;

// Expr -> RelFactor ( RelOpExpr RelFactor )*
Function ExprExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePoint: TSize;
  mRightNode: PAstNode;
  mHeadNode: PBinaryOpNode;
  mCurrNode: PBinaryOpNode;
  mNewNode: PBinaryOpNode;
Begin
  If Not RelFactorRule(Parser, mRightNode) Then
  Begin
    Parser.Error := 'Relational expression expected.';
    Ast := nil;
    Result := False;
    Exit;
  End;

  New(mHeadNode);
  TBinaryOpNode_Create(mHeadNode);
  mCurrNode := mHeadNode;
  mCurrNode.RightNode := mRightNode;
  // the loop: ( RelOpExpr RelFactor ) * 
  Result := True;
  While Not TParser_Term(Parser, eEof) Do
  Begin
    mSavePoint := Parser.FCurrentToken;
    If Not RelOpRule(Parser, PAstNode(mNewNode)) Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      Break;
    End;
    If Not RelFactorRule(Parser, mRightNode) Then
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
