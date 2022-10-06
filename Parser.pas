Unit Parser;
{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}
{.$DEFINE DEBUG}

Interface

Uses
  Lexer, List, TypeDef, ASTNode;

Type
  PParser = ^TParser;

  TSymbolFunc = Function(Parser: PParser; Out Ast: PAstNode): Boolean;

  TExpressionFunc = Function(Parser: PParser; Out Ast: PAstNode): Boolean;

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

Function TParser_GetCurrentToken(Self: PParser): PToken;

Function TParser_Term(Self: PParser; TokenKind: TTokenKind): Boolean;

Function TParser_Prod(Self: PParser; Out Ast: PAstNode; Rules: TArray<
  TExpressionFunc>): Boolean;

Procedure TParser_Destroy(Self: PParser);

Procedure OutputAST(P: PAstNode);

Implementation

Uses
  LiteralNode, BinaryOpNode {$IFNDEF FPC}, System.Rtti{$ENDIF};

Function TParser_Parse(Self: PParser): Boolean;
Begin
  Result := Self.MainProductionRule(Self, Self.Ast) And TParser_Term(Self,
    TTokenKind.eEof);
End;

Function TParser_Create(Lexer: PLexer; ProductionRule: TSymbolFunc): PParser;
Begin
  New(Result);
  Result.FLexer := Lexer;
  Result.MainProductionRule := ProductionRule;
  Result.FTokenList := TList_Create(SizeOf(TToken), 5);
  Result.FCurrentToken := 0;
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

Function TParser_Term(Self: PParser; TokenKind: TTokenKind): Boolean;
Begin
  If TParser_GetNextToken(Self) Then
  Begin
    Result := TParser_IsToken(Self, TokenKind);
    If Not Result Then
    Begin
      Dec(Self.FCurrentToken);
    End;
    Exit;
  End;
  Result := (TokenKind = TTokenKind.eEof);
End;

Function TParser_GetNextToken(Self: PParser): Boolean;
{$IFDEF DEBUG}
Var
  t: String;
{$ENDIF}
Begin
  Inc(Self.FCurrentToken);
  Result := True;
  If Self.FCurrentToken - 1 = Self.FTokenList.Size Then
  Begin
    Result := TLexer_GetNextToken(Self.FLexer);
    If Result Then
    Begin
      TList_PushBack(Self.FTokenList, @(Self.FLexer.CurrentToken));
      {$IFDEF DEBUG}
      {$IFDEF FPC}
      WriteStr(t, TParser_GetCurrentToken(Self).Kind);
      {$ELSE}
      t := TRttiEnumerationType.GetName(TParser_GetCurrentToken(Self).Kind);
      {$ENDIF}
      Writeln('> TOKEN: [' + TParser_GetCurrentToken(Self).Value + '] is ' + t);
        {$ENDIF}
    End
    Else
    Begin
      Dec(Self.FCurrentToken);
    End;
  End;
End;

Function TParser_IsToken(Self: PParser; TokenKind: TTokenKind): Boolean;
Begin
  Result := (TParser_GetCurrentToken(Self).Kind = TokenKind);
End;

Function TParser_Prod(Self: PParser; Out Ast: PAstNode; Rules: TArray<
  TExpressionFunc>): Boolean;
Var
  I: Byte;
  mRule: TExpressionFunc;
Begin
  For I := Low(Rules) To High(Rules) Do
  Begin
    mRule := Rules[I];
    If mRule(Self, Ast) Then
    Begin
      Result := True;
      Exit;
    End;
  End;
  Result := False;
End;

Function TParser_GetCurrentToken(Self: PParser): PToken;
Begin
  Result := PToken(TList_Get(Self.FTokenList, Self.FCurrentToken - 1));
End;

Procedure OutputAST(P: PAstNode);
Var
  t: String;
  n: PBinaryOpNode;
Begin
  Write(' ( ');
  Case P.NodeType Of
    $1:
      Begin
        n := PBinaryOpNode(P.Data);
      {$IFDEF FPC}
        WriteStr(t, n.OpType);
      {$ELSE}
        t := TRttiEnumerationType.GetName(n.OpType);
      {$ENDIF}
        Write(t, ' ');
        If n.LeftNode <> nil Then
          OutputAST(n.LeftNode);
        Write(' ');
        If n.RightNode <> nil Then
          OutputAST(n.RightNode);
      End;
    $2:
      Begin
        Write(PLiteralNode(P.Data).Value);
      End;
  End;
  Write(' ) ');
End;

End.

