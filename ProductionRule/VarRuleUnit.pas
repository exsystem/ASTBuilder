Unit VarRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function VarRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function VarExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  ExprRuleUnit, UnaryOpNode, IdNode, TypeDef, ArrayAccessNode,
  MemberRefNode, DerefNode, List;

// Var -> (AT Id | Id) (LBRACK Expr (COMMA Expr)* RBRACK | RBRACK2 Expr (COMMA Expr)* RBRACK2 | DOT Id | POINTER)*
Function VarExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Label
  S1, S2, S3, S4, S5, S6, S7, S51;
Var
  mSavePoint: TSize;
  mSavePoint2: TSize;
  mAddressNode: PUnaryOpNode;
  mNewNode: PAstNode;
  mExpr: PAstNode;
Begin
  // ADDR Id
  S1:
    // INITIALIZATION
    mAddressNode := nil;
  If Not TParser_Term(Parser, eAt) Then
  Begin
    Parser.Error := '@ expected.';
    Result := False;
    Goto S2;
  End;
  If Not TParser_Term(Parser, eId) Then
  Begin
    Parser.Error := 'Identifier expected.';
    Result := False;
    Goto S2;
  End;

  // IF TRUE:
  New(PIdNode(Ast));
  TIdNode_Create(PIdNode(Ast), TParser_GetCurrentToken(Parser).Value);
  New(mAddressNode);
  TUnaryOpNode_Create(mAddressNode);
  mAddressNode.OpType := eAddress;
  Result := True;
  Goto S3;

  // Id
  S2:
    If Not TParser_Term(Parser, eId) Then
    Begin
      Parser.Error := 'Identifier expected.';
      Result := False;
      Exit;
    End;

  // IF TRUE:
  New(PIdNode(Ast));
  TIdNode_Create(PIdNode(Ast), TParser_GetCurrentToken(Parser).Value);
  Result := True;

  // (LBRACK Expr (COMMA Expr)* RBRACK | RBRACK2 Expr (COMMA Expr)* RBRACK2 | DOT Id | POINTER)*
  S3:
    Result := True;
  While Not TParser_Term(Parser, eEof) Do
  Begin
    mSavePoint := Parser.FCurrentToken;

    // LBRACK Expr (COMMA Expr)* RBRACK 
    S4:
      If Not TParser_Term(Parser, eLBrack) Then
      Begin
        Parser.FCurrentToken := mSavePoint;
        Goto S5;
      End;
    If Not ExprRule(Parser, mExpr) Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      Goto S5;
    End;

    // IF TRUE:
    New(PArrayAccessNode(mNewNode));
    TArrayAccessNode_Create(PArrayAccessNode(mNewNode), Ast);
    TList_PushBack(PArrayAccessNode(mNewNode).Indices, @mExpr);

    // (COMMA Expr)*
    While Not TParser_Term(Parser, eEof) Do
    Begin
      mSavePoint2 := Parser.FCurrentToken;
      If Not TParser_Term(Parser, eComma) Then
      Begin
        Parser.FCurrentToken := mSavePoint2;
        Goto S51;
      End;
      If Not ExprRule(Parser, mExpr) Then
      Begin
        Parser.FCurrentToken := mSavePoint2;
        Goto S51;
      End;
      // IF TRUE:
      TList_PushBack(PArrayAccessNode(mNewNode).Indices, @mExpr);
    End;

    S51:
      If Not TParser_Term(Parser, eRBrack) Then
      Begin
        Parser.FCurrentToken := mSavePoint;
        // IF FALSE:
        PArrayAccessNode(mNewNode).ArrayExpression := nil;
        TArrayAccessNode_Destroy(mNewNode);
        Dispose(PArrayAccessNode(mNewNode));
        Goto S5;
      End;

    // IF TRUE:
    Ast := mNewNode;
    Continue;

    // LBRACK2 Expr (COMMA Expr)* RBRAC2 
    S5:
      If Not TParser_Term(Parser, eLBrack2) Then
      Begin
        Parser.FCurrentToken := mSavePoint;
        Goto S6;
      End;
    If Not ExprRule(Parser, mExpr) Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      Goto S6;
    End;

    // IF TRUE:
    New(PArrayAccessNode(mNewNode));
    TArrayAccessNode_Create(PArrayAccessNode(mNewNode), Ast);
    TList_PushBack(PArrayAccessNode(mNewNode).Indices, @mExpr);

    // (COMMA Expr)*
    While Not TParser_Term(Parser, eEof) Do
    Begin
      mSavePoint2 := Parser.FCurrentToken;
      If Not TParser_Term(Parser, eComma) Then
      Begin
        Parser.FCurrentToken := mSavePoint2;
        Goto S6;
      End;
      If Not ExprRule(Parser, mExpr) Then
      Begin
        Parser.FCurrentToken := mSavePoint2;
        Goto S6;
      End;
      // IF TRUE:
      TList_PushBack(PArrayAccessNode(mNewNode).Indices, @mExpr);
    End;

    If Not TParser_Term(Parser, eRBrack2) Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      // IF FALSE:
      PArrayAccessNode(mNewNode).ArrayExpression := nil;
      TArrayAccessNode_Destroy(mNewNode);
      Dispose(PArrayAccessNode(mNewNode));
      Goto S6;
    End;

    // IF TRUE:
    Ast := mNewNode;
    Continue;

    // DOT Id
    S6:
      If Not TParser_Term(Parser, eDot) Then
      Begin
        Parser.FCurrentToken := mSavePoint;
        Parser.Error := '. expected.';
        Goto S7;
      End;
    If Not TParser_Term(Parser, eId) Then
    Begin
      Parser.FCurrentToken := mSavePoint;
      Parser.Error := 'Identifer expected.';
      Goto S7;
    End;
    // IF TRUE:
    New(PMemberRefNode(mNewNode));
    TMemberRefNode_Create(PMemberRefNode(mNewNode),
      Ast, TParser_GetCurrentToken(Parser).Value);
    Ast := mNewNode;
    Continue;

    // POINTER
    S7:
      If Not TParser_Term(Parser, ePointer) Then
      Begin
        Parser.FCurrentToken := mSavePoint;
        Parser.Error := '^ expected.';
        Break;
      End;
    // IF TRUE:
    New(PDerefNode(mNewNode));
    TDerefNode_Create(PDerefNode(mNewNode), Ast);
    Ast := mNewNode;
    Continue;
  End;

  If mAddressNode <> nil Then
  Begin
    mAddressNode.Value := Ast;
    Ast := PAstNode(mAddressNode);
  End;
End;

Function VarRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := VarExpression1(Parser, Ast);
End;

End.
