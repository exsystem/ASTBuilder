Unit Parser;

{$MODE DELPHI}
Interface

Uses
  Lexer, List, TypeDef, ASTNode;

Type
  PParser = ^TParser;

  TSymbolFunc = Function(Parser: PParser; out Ast: PAstNode): Boolean;
  TExpressionFunc = Function(Parser: PParser; out Ast: PAstNode): Boolean;

  TParser = Record
    FLexer: PLexer;
    FTokenList: PList;
    FCurrentToken: TSize;
    MainProductionRule: TSymbolFunc;
    Ast: PAstNode;
  End;

Function TParser_Create(Lexer: PLexer; ProductionRule: TSymbolFunc): PParser;
Function TParser_Parse(Self: PParser): Boolean;
Function TParser_GetNextToken(Self: PParser): Boolean;
Function TParser_IsToken(Self: PParser; TokenKind: TTokenKind): Boolean;
Function TParser_MatchNextToken(Self: PParser; TokenKind: TTokenKind): Boolean;
Procedure TParser_Destroy(Self: PParser);

Implementation

Function TParser_Parse(Self: PParser): Boolean;
Begin
  Result := Self.MainProductionRule(Self, Self.Ast) And
    TParser_MatchNextToken(Self, TTokenKind.eEof);
End;

Function TParser_Create(Lexer: PLexer; ProductionRule: TSymbolFunc): PParser;
Begin
  New(Result);
  Result.FLexer := Lexer;
  Result.MainProductionRule := ProductionRule;
  Result.FTokenList := TList_Create(SizeOf(TToken), 5);
  Result.FCurrentToken := Pred(0);
  Result.Ast := nil;
End;

Procedure TParser_Destroy(Self: PParser);
Begin
  TList_Destroy(Self.FTokenList);
  If Self.Ast <> nil Then
  Begin
    TAstNode_Destroy(Self.Ast);
  End;
  Dispose(Self);
End;

Function TParser_MatchNextToken(Self: PParser; TokenKind: TTokenKind): Boolean;
Begin
  Result := TParser_GetNextToken(Self) And TParser_IsToken(Self, TokenKind);
  Exit;
  If Result Then
  Begin
    WriteLn(PToken(TList_Get(Self.FTokenList, Self.FCurrentToken)).Value);
  End;
End;

Function TParser_GetNextToken(Self: PParser): Boolean;
Begin
  Inc(Self.FCurrentToken);
  If Self.FCurrentToken = Self.FTokenList.Size Then
  Begin
    Result := TLexer_GetNextToken(Self.FLexer);
    TList_PushBack(Self.FTokenList, @(Self.FLexer.CurrentToken));
  End;
End;

Function TParser_IsToken(Self: PParser; TokenKind: TTokenKind): Boolean;
Begin
  Result := (PToken(TList_Get(Self.FTokenList, Self.FCurrentToken)).Kind = TokenKind);
  If Not Result Then
  Begin
    Dec(Self.FCurrentToken);
  End;
End;


End.
