Unit StringFactorRuleUnit;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  Parser, Lexer, ASTNode;

Function StringFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;

Function StringFactorRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;

Function StringFactorRuleExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;

Function StringFactorRuleExpression3(Parser: PParser; Var Ast: PAstNode): Boolean;

Implementation

Uses
  TypeDef, IdNode, TermNode, GroupNode, TermExprRuleUnit,
  StringNode, RangeNode;

// stringFactor -> char DoubleDots char
Function StringFactorRuleExpression1(Parser: PParser; Var Ast: PAstNode): Boolean;
Var
  mSavePointS1: TSize;
  mFrom, mTo: String;
Label
  S1, S2, S3, S4;
Begin
  S1:
    mSavePointS1 := Parser.FCurrentToken;
  If TParser_Term(Parser, eChar) Then
  Begin
    mFrom := TParser_GetCurrentToken(Parser).Value;
  End
  Else
  Begin
    Result := False;
    Exit;
  End;
  S2:
    If TParser_Term(Parser, eDoubleDots) Then
    Begin
    End
    Else
    Begin
      Parser.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S3:
    If TParser_Term(Parser, eChar) Then
    Begin
      mTo := TParser_GetCurrentToken(Parser).Value;
    End
    Else
    Begin
      Parser.FCurrentToken := mSavePointS1;
      Result := False;
      Exit;
    End;
  S4:
    If mFrom[2] = '\' Then
      // TODO extract a util function. and add more chars allowing escaping.
    Begin
      Case mFrom[3] Of
        'n': mFrom := #13;
        'r': mFrom := #10;
        't': mFrom := #20;
        Else
          mFrom := mFrom[3];
      End;
    End
    Else
    Begin
      mFrom := mFrom[2];
    End;
  If mTo[2] = '\' Then
  Begin
    Case mTo[3] Of
      'n': mTo := #13;
      'r': mTo := #10;
      't': mTo := #20;
      Else
        mTo := mTo[3];
    End;
  End
  Else
  Begin
    mTo := mTo[2];
  End;
  TRangeNode_Create(PRangeNode(Ast), mFrom[1], mTo[1]);
  Result := True;
End;

// stringFactor -> char
Function StringFactorRuleExpression2(Parser: PParser; Var Ast: PAstNode): Boolean;
Label
  S1, S2;
Begin
  S1:
    If TParser_Term(Parser, eChar) Then
    Begin
      TStringNode_Create(PStringNode(Ast), TParser_GetCurrentToken(Parser).Value);
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    Result := True;
End;

// stringFactor -> string
Function StringFactorRuleExpression3(Parser: PParser; Var Ast: PAstNode): Boolean;
Label
  S1, S2;
Begin
  S1:
    If TParser_Term(Parser, eString) Then
    Begin
      TStringNode_Create(PStringNode(Ast),
      TParser_GetCurrentToken(Parser).Value);
    End
    Else
    Begin
      Result := False;
      Exit;
    End;
  S2:
    Result := True;
End;

Function StringFactorRule(Parser: PParser; Var Ast: PAstNode): Boolean;
Begin
  Result := StringFactorRuleExpression1(Parser, Ast) Or
    StringFactorRuleExpression2(Parser, Ast) Or StringFactorRuleExpression3(Parser, Ast);
End;

End.
