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
  //Result := TParser_Prod(Parser, Ast, [@FactorExpression1]);
  Result := FactorExpression1(Parser, Ast);
End;

Function FactorExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
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

  Result := TermRuleUnit.TermRule(Parser, mCurrNode.RightNode);
  If Result = False Then
  Begin
    TBinaryOpNode_Destroy(PAstNode(mHeadNode));
    Dispose(mHeadNode);
    Parser.Error := 'Expression expected.';
    Exit;
  End;
  While Not TParser_Term(Parser, eEof) Do
  Begin
    New(mNewNode);
    TBinaryOpNode_Create(mNewNode);

    mSavePoint := Parser.FCurrentToken;
    mResult := False;
    If TParser_Term(Parser, eMul) Then
    Begin
      mNewNode.OpType := eMultiply;
      mResult := True;
    End
    Else If TParser_Term(Parser, eSlash) Then
    Begin
      mNewNode.OpType := eDivide;
      mResult := True;
    End;
    mResult := mResult And TermRuleUnit.TermRule(Parser, mNewNode.RightNode);
    If Not mResult Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      TBinaryOpNode_Destroy(PAstNode(mNewNode));
      Dispose(mNewNode);
      Parser.Error := 'Expression expected.';
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
