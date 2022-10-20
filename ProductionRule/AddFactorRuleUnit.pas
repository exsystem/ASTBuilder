Unit AddFactorRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function AddFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;

Function AddFactorExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  SignFactorRuleUnit, TypeDef, BinaryOpNode, MulOpRuleUnit;

Function AddFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := AddFactorExpression1(Parser, Ast);
End;

Function AddFactorExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePoint: TSize;
  mRightNode: PAstNode;
  mHeadNode: PBinaryOpNode;
  mCurrNode: PBinaryOpNode;
  mNewNode: PBinaryOpNode;
Begin
  If Not SignFactorRule(Parser, mRightNode) Then
  Begin
    Parser.Error := 'Term expression expected.';
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
    If Not MulOpRule(Parser, PAstNode(mNewNode)) Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      Break;
    End;
    If Not SignFactorRule(Parser, mRightNode) Then
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
