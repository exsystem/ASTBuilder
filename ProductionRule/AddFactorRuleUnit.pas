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
  TermRuleUnit, TypeDef, BinaryOpNode, MulOpRuleUnit;

Function AddFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := AddFactorExpression1(Parser, Ast);
End;

Function AddFactorExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
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

  Result := TermRule(Parser, mCurrNode.RightNode);
  If Result = False Then
  Begin
    TBinaryOpNode_Destroy(PAstNode(mHeadNode));
    Dispose(mHeadNode);
    Parser.Error := 'Term expression expected.';
    Exit;
  End;
  While Not TParser_Term(Parser, eEof) Do
  Begin
    mSavePoint := Parser.FCurrentToken;
    mNewNode := nil;
    mResult := MulOpRule(Parser, PAstNode(mNewNode)) And
      TermRule(Parser, mNewNode.RightNode);
    If Not mResult Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      If mNewNode <> nil Then
      Begin
        TBinaryOpNode_Destroy(PAstNode(mNewNode));
        Dispose(mNewNode);
      End;
      Parser.Error := 'Term expression expected.';
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
