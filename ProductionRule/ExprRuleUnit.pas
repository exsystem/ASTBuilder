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
  mHeadNode: PBinaryOpNode;
  mCurrNode: PBinaryOpNode;
  mNewNode: PBinaryOpNode;
  mResult: Boolean;
Begin
  New(mHeadNode);
  TBinaryOpNode_Create(mHeadNode);
  mCurrNode := mHeadNode;

  Result := RelFactorRule(Parser, mCurrNode.RightNode);
  If Result = False Then
  Begin
    TBinaryOpNode_Destroy(PAstNode(mHeadNode));
    Dispose(mHeadNode);
    Parser.Error := 'Relational expression expected.';
    Exit;
  End;
  // the loop: ( RelOpExpr RelFactor ) * 
  While Not TParser_Term(Parser, eEof) Do
  Begin
    mSavePoint := Parser.FCurrentToken;
    mNewNode := nil;
    mResult := RelOpRule(Parser, PAstNode(mNewNode)) And
      RelFactorRule(Parser, mNewNode.RightNode);
    If Not mResult Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      If mNewNode <> nil Then
      Begin
        TBinaryOpNode_Destroy(PAstNode(mNewNode));
        Dispose(mNewNode);
      End;
      Parser.Error := 'Relational expression expected.';
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
