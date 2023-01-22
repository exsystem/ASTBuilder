Unit TermFactorRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function TermFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;

Function TermFactorRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Function TermFactorRuleExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, List, ClassUtils, IdNode, TermNode, GroupNode, TermExprRuleUnit,
  StringFactorRuleUnit;

// termFactor -> stringFactor ( QuestionMark | Asterisk ) ?
Function TermFactorRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS2: TSize;
  mIdNode: PAstNode;
Label
  S1, S2, S3;
Begin
  S1:
    If StringFactorRule(Parser, mIdNode) Then
    Begin
      // NOP
    End
    Else
    Begin
      Result := False; // S1 is a Non-Accepted State Node in DFA.
      Exit;
    End;
  S2:
    mSavePointS2 := Parser.FCurrentToken;
  If TParser_Term(Parser, eQuestionMark) Then
  Begin
    TGroupNode_Create(PGroupNode(Ast));
    TList_PushBack(PGroupNode(Ast).Terms, @mIdNode);
    PGroupNode(Ast).GroupType := TGroupType.eOptional;
    PGroupNode(Ast).IsAlternational := False;
  End
  Else If TParser_Term(Parser, eAsterisk) Then
  Begin
    TGroupNode_Create(PGroupNode(Ast));
    TList_PushBack(PGroupNode(Ast).Terms, @mIdNode);
    PGroupNode(Ast).GroupType := TGroupType.eMultiple;
    PGroupNode(Ast).IsAlternational := False;
  End
  Else
  Begin
    Parser.FCurrentToken := mSavePointS2;
    Ast := mIdNode;
    Result := True; // S2 is a accpeted state node in DFA.
    Exit;
  End;
  S3:
    Result := True;
End;

// termFactor -> LParen termExpr RParen ( QuestionMark | Asterisk ) ?
Function TermFactorRuleExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS4: TSize;
Label
  S1, S2, S3, S4, S5;
Var
  mExprNode: PAstNode;
Begin
  S1:
    If TParser_Term(Parser, eLParen) Then
    Begin
      // NOP
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    If TermExprRule(Parser, mExprNode) Then
    Begin
      // NOP
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S3:
    If TParser_Term(Parser, eRParen) Then
    Begin
      If InstanceOf(mExprNode, @mTGroupNode_VMT) Then
      Begin
        Ast := mExprNode;
      End
      Else
      Begin
        TGroupNode_Create(PGroupNode(Ast));
        PGroupNode(Ast).IsAlternational := False;
        TList_PushBack(PGroupNode(Ast).Terms, @mExprNode);
      End;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S4:
    mSavePointS4 := Parser.FCurrentToken;
  If TParser_Term(Parser, eQuestionMark) Then
  Begin
    PGroupNode(Ast).GroupType := TGroupType.eOptional;
  End
  Else If TParser_Term(Parser, eAsterisk) Then
  Begin
    PGroupNode(Ast).GroupType := TGroupType.eMultiple;
  End
  Else
  Begin
    Parser.FCurrentToken := mSavePointS4;
    Result := True;
    Exit;
  End;
  S5:
    Result := True;
End;

Function TermFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := TermFactorRuleExpression1(Parser, Ast) Or
    TermFactorRuleExpression2(Parser, Ast);
End;

End.
