{ Unit ActionsRuleUnit; }
Unit ASRUNIT;

{$I define.inc}

Interface

Uses
  Parser, ASTNode;

Function ActionsRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Function ActionsRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, IdNode, GrpNode, TrmRNode, ACTRUNIT, GRMRNODE,
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, GLEXER, GPARSER;

{ actions -> action (Comma action)* }
Function ActionsRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS2: TSize;
Label
  S1, S2;
Begin
  { ATTENSION: IT'S NOT actions -> (action Comma)* action }
  S1:
    If ActionRule(Parser, Ast) Then
    Begin
      {NOP}
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  Result := True;
  S2:
    mSavePointS2 := Parser^.FCurrentToken;
  If TGrammarParser_Term(Parser, eComma) Then
  Begin
    {NOP}
  End
  Else
  Begin
    Parser^.FCurrentToken := mSavePointS2;
    Exit;
  End;
  If ActionRule(Parser, Ast) Then
  Begin
    Goto S2;
  End
  Else
  Begin
    Exit;
  End;
End;

Function ActionsRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := ActionsRuleExpression1(Parser, Ast);
End;

End.
