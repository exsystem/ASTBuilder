Unit FactorRule;

{$MODE DELPHI}

Interface

Uses
  Parser, Lexer, ASTNode;

Function FactorRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Function FactorExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;


Implementation

Uses
  TermRule, TypeDef, BinaryOpNode;

Function FactorRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := FactorExpression1(Parser, Ast);
End;

Function FactorExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
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

  Result := TermRule.TermRule(Parser, mCurrNodeData.RightNode);
  If Result = False Then
  Begin
    TAstNode_Destroy(mHeadNode);
    Exit;
  End;
  While Not TParser_MatchNextToken(Parser, TTokenKind.eEof) Do
  Begin
    mNewNode := TBinaryOpNode_Create();
    mNewNodeData := PBinaryOpNode(mNewNode.Data);

    mTemp := Parser.FCurrentToken;
    If TParser_MatchNextToken(Parser, TTokenKind.eMul) Then
    Begin
      mNewNodeData.OpType := TOpType.eMultiply;
      Result := True;
    End
    Else If TParser_MatchNextToken(Parser, TTokenKind.eDiv) Then
    Begin
      mNewNodeData.OpType := TOpType.eDivide;
      Result := True;
    End;
    Result := Result And TermRule.TermRule(Parser, mCurrNodeData.RightNode);
    If Not Result Then
    Begin
      Parser.FCurrentToken := mTemp;
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
