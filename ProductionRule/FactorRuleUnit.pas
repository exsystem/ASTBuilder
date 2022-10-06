Unit FactorRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function FactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;

Function FactorExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TermRuleUnit, TypeDef, BinaryOpNode;

Function FactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := TParser_Prod(Parser, Ast, [@FactorExpression1]);
    //Result := FactorExpression1(Parser, Ast);
End;

Function FactorExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
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

  Result := TermRuleUnit.TermRule(Parser, mCurrNodeData.RightNode);
  If Result = False Then
  Begin
    TAstNode_Destroy(mHeadNode);
    Exit;
  End;
  While Not TParser_Term(Parser, TTokenKind.eEof) Do
  Begin
    mNewNode := TBinaryOpNode_Create();
    mNewNodeData := PBinaryOpNode(mNewNode.Data);

    mSavePoint := Parser.FCurrentToken;
    mResult := False;
    If TParser_Term(Parser, TTokenKind.eMul) Then
    Begin
      mNewNodeData.OpType := TOpType.eMultiply;
      mResult := True;
    End
    Else If TParser_Term(Parser, TTokenKind.eDiv) Then
    Begin
      mNewNodeData.OpType := TOpType.eDivide;
      mResult := True;
    End;
    mResult := mResult And TermRuleUnit.TermRule(Parser, mNewNodeData.RightNode);
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

