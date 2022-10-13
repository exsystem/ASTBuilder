Unit RelFactorRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function RelFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;

Function RelFactorExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  AddFactorRuleUnit, TypeDef, BinaryOpNode, AddOpRuleUnit;

Function RelFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := RelFactorExpression1(Parser, Ast);
End;

Function RelFactorExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
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

  Result := AddFactorRule(Parser, mCurrNode.RightNode);
  If Result = False Then
  Begin
    TBinaryOpNode_Destroy(PAstNode(mHeadNode));
    Dispose(mHeadNode);
    Parser.Error := 'Add expression expected.';
    Exit;
  End;
  While Not TParser_Term(Parser, eEof) Do
  Begin
    mSavePoint := Parser.FCurrentToken;
    mNewNode := nil;
    mResult := AddOpRule(Parser, PAstNode(mNewNode)) And
      AddFactorRule(Parser, mNewNode.RightNode);
    If Not mResult Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      If mNewNode <> nil Then
      Begin
        TBinaryOpNode_Destroy(PAstNode(mNewNode));
        Dispose(mNewNode);
      End;
      Parser.Error := 'Add expression expected.';
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
