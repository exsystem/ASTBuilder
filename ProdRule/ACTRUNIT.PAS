{ Unit ActionRuleUnit; }
Unit ACTRUNIT;

{$I define.inc}

Interface

Uses
  Parser, Lexer, ASTNode;

Function ActionRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function ActionRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, IdNode, GrpNode, TrmRNode, TERUnit, TRRUNIT, GRMRNODE, NFA,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil, GLEXER, CLEXER, GPARSER;

{ action -> skip | (PushMode LParen Id RParen) | PopMode }
Function ActionRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS2, mSavePointS3: TSize;
Label
  S1, S2, S3;
Begin
  S1:
    If TGrammarParser_Term(Parser, eSkip) Then
    Begin
      TTermRuleNode_AddSkipCommand(PTermRuleNode(Ast));
      Goto S2;
    End
    Else If TGrammarParser_Term(Parser, ePushMode) Then
    Begin
      {NOP}
    End
    Else If TGrammarParser_Term(Parser, ePopMode) Then
    Begin
      TTermRuleNode_AddPopModeCommand(PTermRuleNode(Ast));
      Goto S2;
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  If TGrammarParser_Term(Parser, eLParen) Then
  Begin
    {NOP}
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  If TGrammarParser_Term(Parser, eId) Then
  Begin
    TTermRuleNode_AddPushModeCommand(PTermRuleNode(Ast),
      TParser_GetCurrentToken(Parser)^.Value);
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  If TGrammarParser_Term(Parser, eRParen) Then
  Begin
    {NOP}
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  S2:
    Result := True;
End;

Function ActionRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := ActionRuleExpression1(Parser, Ast);
End;

End.
