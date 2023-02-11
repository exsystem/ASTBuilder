Unit TermExprRuleUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, NFA;

Function TermExprRule(Parser: PParser; Var Nfa: PNfa): Boolean;

Function TermExprRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;

Implementation

Uses
  TypeDef, IdNode, TermNode, GroupNode, TermFactorRuleUnit;

// termExpr -> termFactor* ( Or termFactor* )*
Function TermExprRuleExpression1(Parser: PParser; Var Nfa: PNfa): Boolean;
Var
  mSavePointS1, mSavePointS2: TSize;
  mFactorNode: PNfa;
  mGroupNode1, mGroupNodeN: PNfa;
  mExprNode: PNfa;
Label
  S1, S2;
Begin
  mGroupNode1 := nil;
  mExprNode := nil;
  Nfa := nil;
  mGroupNodeN := nil;
  S1:
    mSavePointS1 := Parser.FCurrentToken;
  If TermFactorRule(Parser, mFactorNode) Then
  Begin
    If mGroupNode1 = nil Then
    Begin
      mGroupNode1 := mFactorNode;
      Nfa := mGroupNode1;
    End
    Else
    Begin
      TNfa_Concat(mGroupNode1, mFactorNode);
    End;
    Goto S1;
  End
  Else If TParser_Term(Parser, TGrammarTokenKind.eOr) Then
  Begin
    If mExprNode = nil Then
    Begin
      mExprNode := mGroupNode1;
    End
    Else
    Begin
      Nfa := mExprNode;
    End;
  End
  Else
  Begin
    Parser.FCurrentToken := mSavePointS1;
    Result := True;
    Exit;
  End;
  S2:
    mSavePointS2 := Parser.FCurrentToken;
  If TermFactorRule(Parser, mFactorNode) Then
  Begin
    If mGroupNodeN = nil Then
    Begin
      mGroupNodeN := mFactorNode;
    End
    Else
    Begin
      TNfa_Concat(mGroupNodeN, mFactorNode);
    End;
    Goto S2;
  End
  Else If TParser_Term(Parser, TGrammarTokenKind.eOr) Then
  Begin
    TNfa_Alternative(mExprNode, mGroupNodeN);
    mGroupNodeN := nil;
    Goto S2;
  End
  Else
  Begin
    If mExprNode <> nil Then
    Begin
      TNfa_Alternative(mExprNode, mGroupNodeN);
      Nfa := mExprNode;
    End;
    Parser.FCurrentToken := mSavePointS2;
    Result := True;
  End;
End;

Function TermExprRule(Parser: PParser; Var Nfa: PNfa): Boolean;
Begin
  Result := TermExprRuleExpression1(Parser, Nfa);
End;

End.
