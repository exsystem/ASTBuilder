Unit Parser;

{$MODE DELPHI}
Interface

Uses
  Lexer, List, TypeDef;

Type
  PParser = ^TParser;

  TSymbolFunc = Function(Parser: PParser): Boolean;
  TExpressionFunc = Function(Parser: PParser): Boolean;

  TParser = Record
    FLexer: PLexer;
    FTokenList: PList;
    FCurrentToken: TSize;
    MainProductionRule: TSymbolFunc;
  End;

Function TParser_Create(Lexer: PLexer; ProductionRule: TSymbolFunc): PParser;
Function TParser_Parse(Self: PParser): Boolean;
Function TParser_GetNextToken(Self: PParser): Boolean;
Function TParser_IsToken(Self: PParser; TokenKind: TTokenKind): Boolean;
Function TParser_Term(Self: PParser; TokenKind: TTokenKind): Boolean;
Function TParser_Prod(Self: PParser; Rules: TArray<TSymbolFunc>): Boolean;
Procedure TParser_Destroy(Self: PParser);

Implementation

Function TParser_Parse(Self: PParser): Boolean;
Begin
  Result := Self.MainProductionRule(Self) And TParser_Term(Self, TTokenKind.eEof);
End;

Function TParser_Create(Lexer: PLexer; ProductionRule: TSymbolFunc): PParser;
Begin
  New(Result);
  Result.FLexer := Lexer;
  Result.MainProductionRule := ProductionRule;
  Result.FTokenList := TList_Create(SizeOf(TToken), 5);
  Result.FCurrentToken := Pred(0);
End;

Procedure TParser_Destroy(Self: PParser);
Begin
  TList_Destroy(Self.FTokenList);
  Dispose(Self);
End;

Function TParser_Term(Self: PParser; TokenKind: TTokenKind): Boolean;
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
  // Exit;
  If Not Result Then
  Begin
    Dec(Self.FCurrentToken);
  End;
End;

Function TParser_Prod(Self: PParser; Rules: TArray<TSymbolFunc>): Boolean;
Var
  //mSave: TSize;
  I: Byte;
  mRule: TSymbolFunc;
Begin
  //mSave := Self.FCurrentToken;
  For I := Low(Rules) To High(Rules) Do
  Begin
    //Self.FCurrentToken := mSave;
    mRule := Rules[I];
    If mRule(Self) Then
    Begin
      Exit(True);
    End;
  End;
  Exit(False);
End;

End.
