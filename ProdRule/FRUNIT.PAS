{ Unit FactorRuleUnit; }
Unit FRUnit;

{$I define.inc}

Interface

Uses
  Parser, Lexer, ASTNode;

Function FactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;

Function FactorRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Function FactorRuleExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;

Function FactorRuleExpression3(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, List, ClsUtils, IdNode, TrmNode, GrpNode, ExpRUnit,
 {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

{ factor -> id ( QuestionMark | Plus | Asterisk ) ? }
{ DFA: (S1)--[id]->((S2))--[?, +, *]->((S3))    }
Function FactorRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS2: TSize;
  mIdNode: PAstNode;
Label
  S1, S2, S3;
Begin
  S1:
    If TParser_TermByGrammarTokenKind(Parser, eId) Then
    Begin
      TIdNode_Create(PIdNode(mIdNode), TParser_GetCurrentToken(Parser)^.Value);
    End
    Else
    Begin
      Result := False; { S1 is a Non-Accepted State Node in DFA. }
      Exit;
    End;
  S2:
    mSavePointS2 := Parser^.FCurrentToken;
  If TParser_TermByGrammarTokenKind(Parser, eQuestionMark) Then
  Begin
    TGroupNode_Create(PGroupNode(Ast));
    TList_PushBack(PGroupNode(Ast)^.Terms, @mIdNode);
    PGroupNode(Ast)^.GroupType := eOptional;
    PGroupNode(Ast)^.IsAlternational := False;
  End
  Else If TParser_TermByGrammarTokenKind(Parser, ePlus) Then
  Begin
    TGroupNode_Create(PGroupNode(Ast));
    TList_PushBack(PGroupNode(Ast)^.Terms, @mIdNode);
    PGroupNode(Ast)^.GroupType := eOneOrMore;
    PGroupNode(Ast)^.IsAlternational := False;
  End
  Else If TParser_TermByGrammarTokenKind(Parser, eAsterisk) Then
  Begin
    TGroupNode_Create(PGroupNode(Ast));
    TList_PushBack(PGroupNode(Ast)^.Terms, @mIdNode);
    PGroupNode(Ast)^.GroupType := eMultiple;
    PGroupNode(Ast)^.IsAlternational := False;
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS2;
    Ast := mIdNode;
    Result := True; { S2 is a accpeted state node in DFA. }
    Exit;
  End;
  S3:
    Result := True;
End;

{ factor -> term ( QuestionMark | Plus | Asterisk ) ? }
{ DFA: (S1)--[id]->((S2))--[?, +, *]->((S3))      }
Function FactorRuleExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS2: TSize;
  mTermNode: PAstNode;
Label
  S1, S2, S3;
Begin
  S1:
    If TParser_TermByGrammarTokenKind(Parser, eTerm) Then
    Begin
      TTermNode_Create(PTermNode(mTermNode));
      FreeStr(PTermNode(mTermNode)^.Token.Error);
      FreeStr(PTermNode(mTermNode)^.Token.Value);
      FreeStr(PTermNode(mTermNode)^.Token.Kind.TermRule);
      PTermNode(mTermNode)^.Token := TParser_GetCurrentToken(Parser)^;
      PTermNode(mTermNode)^.Token.Error := StrNew(PTermNode(mTermNode)^.Token.Error);
      PTermNode(mTermNode)^.Token.Value := StrNew(PTermNode(mTermNode)^.Token.Value);
      PTermNode(mTermNode)^.Token.Kind.TermRule :=
        StrNew(PTermNode(mTermNode)^.Token.Kind.TermRule);
    End
    Else
    Begin
      Result := False; { S1 is a Non-Accepted State Node in DFA. }
      Exit;
    End;
  S2:
    mSavePointS2 := Parser^.FCurrentToken;
  If TParser_TermByGrammarTokenKind(Parser, eQuestionMark) Then
  Begin
    TGroupNode_Create(PGroupNode(Ast));
    TList_PushBack(PGroupNode(Ast)^.Terms, @mTermNode);
    PGroupNode(Ast)^.GroupType := eOptional;
    PGroupNode(Ast)^.IsAlternational := False;
  End
  Else If TParser_TermByGrammarTokenKind(Parser, ePlus) Then
  Begin
    TGroupNode_Create(PGroupNode(Ast));
    TList_PushBack(PGroupNode(Ast)^.Terms, @mTermNode);
    PGroupNode(Ast)^.GroupType := eOneOrMore;
    PGroupNode(Ast)^.IsAlternational := False;
  End
  Else If TParser_TermByGrammarTokenKind(Parser, eAsterisk) Then
  Begin
    TGroupNode_Create(PGroupNode(Ast));
    TList_PushBack(PGroupNode(Ast)^.Terms, @mTermNode);
    PGroupNode(Ast)^.GroupType := eMultiple;
    PGroupNode(Ast)^.IsAlternational := False;
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS2;
    Ast := mTermNode;
    Result := True; { S2 is a accpeted state node in DFA^. }
    Exit;
  End;
  S3:
    Result := True;
End;

{ factor -> LParen expr RParen ( QuestionMark | Plus | Asterisk ) ? }
Function FactorRuleExpression3(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS4: TSize;
Label
  S1, S2, S3, S4, S5;
Var
  mExprNode: PAstNode;
Begin
  S1:
    If TParser_TermByGrammarTokenKind(Parser, eLParen) Then
    Begin
      { NOP }
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    If ExprRule(Parser, mExprNode) Then
    Begin
      { NOP }
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S3:
    If TParser_TermByGrammarTokenKind(Parser, eRParen) Then
    Begin
      If InstanceOf(mExprNode, @mTGroupNode_VMT) Then
      Begin
        Ast := mExprNode;
      End
      Else
      Begin
        TGroupNode_Create(PGroupNode(Ast));
        PGroupNode(Ast)^.IsAlternational := False;
        TList_PushBack(PGroupNode(Ast)^.Terms, @mExprNode);
      End;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S4:
    mSavePointS4 := Parser^.FCurrentToken;
  If TParser_TermByGrammarTokenKind(Parser, eQuestionMark) Then
  Begin
    PGroupNode(Ast)^.GroupType := eOptional;
  End
  Else If TParser_TermByGrammarTokenKind(Parser, ePlus) Then
  Begin
    PGroupNode(Ast)^.GroupType := eOneOrMore;
  End
  Else If TParser_TermByGrammarTokenKind(Parser, eAsterisk) Then
  Begin
    PGroupNode(Ast)^.GroupType := eMultiple;
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS4;
    Result := True;
    Exit;
  End;
  S5:
    Result := True;
End;

Function FactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := FactorRuleExpression1(Parser, Ast) Or
    FactorRuleExpression2(Parser, Ast) Or FactorRuleExpression3(Parser, Ast);
End;

End.
