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

  TSymbolFunc = Function(Parser: PParser; Var Ast: PAstNode): Boolean;

  TExpressionFunc = Function(Parser: PParser; Var Ast: PAstNode): Boolean;

  TExpressionFuncArray = Array Of TExpressionFunc;

  TParser = Record
    FLexer: PLexer;
    FTokenList: PList;
    FCurrentToken: TSize;
    MainProductionRule: TSymbolFunc;
    Ast: PAstNode;
    Error: String;
  End;

Function TParser_Create(Lexer: PLexer; ProductionRule: TSymbolFunc): PParser;

Function TParser_Parse(Self: PParser): Boolean;

Function TParser_GetNextToken(Self: PParser): Boolean;

Function TParser_IsToken(Self: PParser; TokenKind: TTokenKind): Boolean;

Function TParser_GetCurrentToken(Self: PParser): PToken;

Function TParser_Term(Self: PParser; TokenKind: TTokenKind): Boolean;

{
  Function TParser_Prod(Self: PParser; Var Ast: PAstNode;
  Rules: TExpressionFuncArray): Boolean;
}

Procedure TParser_Destroy(Self: PParser);

Procedure OutputAST(P: PAstNode);

Implementation

Uses
  LiteralNode, BinaryOpNode, UnaryOpNode
  {$IFNDEF FPC},
  {$IFDEF VER150}
  TypInfo
  {$ELSE}
  System.Rtti
  {$ENDIF}
  {$ENDIF}  ;

Function TParser_Parse(Self: PParser): Boolean;
Begin
  Result := Self.MainProductionRule(Self, Self.Ast) And TParser_Term(Self, eEof);
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
    Self.Ast.VMT.Destory(Self.Ast);
    Dispose(Self.Ast);
  End;
  Dispose(Self);
End;

Function TParser_Term(Self: PParser; TokenKind: TTokenKind): Boolean;
Begin
  If (Self.FLexer.NextPos > 1) And (Self.FLexer.CurrentToken.Kind = eUndefined) Then
  Begin
    // Low effeciency! Should stopped the parser immediately! 
    // * Consider `E -> Term(A) or Term(B) or Term(C) ...`
    // * If an undefined token tested out during `Term(A)` with `False` returned, not because of not matching the `A`, you can not stop parsing E with this pattern of chaining terms together by `or`.
    // OR (BETTER CHOICE): Assuming the lexer has preprocessed already, so that it is guaranteed no incorrect tokens during parsing. So this IF-THEN code block should be completely removed!
    Result := False;
    Exit;
  End;
  If TParser_GetNextToken(Self) Then
  Begin
    Result := TParser_IsToken(Self, TokenKind);
    If Not Result Then
    Begin
      Dec(Self.FCurrentToken);
    End;
    Exit;
  End;
  Result := (TokenKind = eEof);
End;

Function TParser_GetNextToken(Self: PParser): Boolean;
{$IFDEF DEBUG}
Var
  t: String;
{$ENDIF}
Begin
  If Self.FCurrentToken = Self.FTokenList.Size Then
  Begin
    Result := TLexer_GetNextToken(Self.FLexer);
    If Result Then
    Begin
      Inc(Self.FCurrentToken);
      TList_PushBack(Self.FTokenList, @(Self.FLexer.CurrentToken));
      {$IFDEF DEBUG}
      {$IFDEF FPC}
      WriteStr(t, TParser_GetCurrentToken(Self).Kind);
      {$ELSE}
      t := TRttiEnumerationType.GetName(TParser_GetCurrentToken(Self).Kind);
      {$ENDIF}
      Writeln('> TOKEN: [' + TParser_GetCurrentToken(Self).Value + '] is ' + t);
      {$ENDIF}
    End;
  End
  Else
  Begin
    Result := True;
    Inc(Self.FCurrentToken);
  End;
End;

Function TParser_IsToken(Self: PParser; TokenKind: TTokenKind): Boolean;
Begin
  Result := (TParser_GetCurrentToken(Self).Kind = TokenKind);
End;

{
Function TParser_Prod(Self: PParser; Var Ast: PAstNode;
  Rules: TExpressionFuncArray): Boolean;
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
}

Function TParser_GetCurrentToken(Self: PParser): PToken;
Begin
  Result := PToken(TList_Get(Self.FTokenList, Self.FCurrentToken - 1));
End;

Procedure OutputAST(P: PAstNode);
Var
  t: String;
  n: PBinaryOpNode;
  m: PUnaryOpNode;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
Begin
  If P = nil Then
  Begin
    Exit;
  End;
  Write(' ( ');
  Case P.NodeType Of
    $1:
    Begin
      n := PBinaryOpNode(P);
      {$IFDEF FPC}
      WriteStr(t, n.OpType);
      {$ELSE}
      {$IFDEF VER150}
      tInfo := TypeInfo(TOpType);
      t := GetEnumName(tInfo, Ord(n.OpType));
      {$ELSE}
      t := TRttiEnumerationType.GetName(n.OpType);
      {$ENDIF}
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
      Write(PLiteralNode(P).Value);
    End;
    $3:
    Begin
      m := PUnaryOpNode(P);
      {$IFDEF FPC}
      WriteStr(t, m.OpType);
      {$ELSE}
      {$IFDEF VER150}
      tInfo := TypeInfo(TOpType);
      t := GetEnumName(tInfo, Ord(m.OpType));
      {$ELSE}
      t := TRttiEnumerationType.GetName(m.OpType);
      {$ENDIF}
      {$ENDIF}
      Write(t, ' ');
      OutputAST(m.Value);
    End;
  End;
  Write(' ) ');
End;

End.
