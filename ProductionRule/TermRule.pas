Unit TermRule;

{$MODE DELPHI}

Interface

Uses
  Parser, Lexer, ASTNode;

Function TermRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Function TermExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Function TermExpression2(Parser: PParser; Out Ast: PAstNode): Boolean;

Implementation

Uses
  ExprRule, LiteralNode, List;

Function TermExpression1(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := TParser_MatchNextToken(Parser, TTokenKind.eNum);
  If Not Result Then
  Begin
    Exit;
  End;
  Ast := TLiteralNode_Create(TLiteralType.eInteger,
    PToken(TList_Get(Parser.FTokenList, Parser.FCurrentToken)).Value);
End;

Function TermRule(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := TermExpression1(Parser, Ast) Or TermExpression2(Parser, Ast);
End;

Function TermExpression2(Parser: PParser; Out Ast: PAstNode): Boolean;
Begin
  Result := (TParser_MatchNextToken(Parser, TTokenKind.eLParent) And
    ExprRule.ExprRule(Parser, Ast) And TParser_MatchNextToken(Parser,
    TTokenKind.eRParent));
  If Not Result Then
  Begin
    Exit;
  End;
  Ast := TLiteralNode_Create(TLiteralType.eInteger,
    PToken(TList_Get(Parser.FTokenList, Parser.FCurrentToken)).Value);
End;

End.
