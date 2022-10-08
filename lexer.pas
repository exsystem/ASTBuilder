Unit Lexer;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  List, TypeDef;

Type
  TTokenKind = (eUndefined, eAdd, eSub, eMul, eDiv, eLParent, eRParent, eNum,
    eEof);

  PToken = ^TToken;

  TToken = Record
    Kind: TTokenKind;
    Value: String;
    StartPos: TSize;
  End;

  PLexer = ^TLexer;

  TLexer = Record
    RuleList: PList;
    Source: String;
    CurrentPos: TSize;
    CurrentChar: Char;
    CurrentToken: TToken;
  End;

  TLexerRuleParser = Function(Lexer: PLexer): Boolean;

  PLexerRule = ^TLexerRule;

  TLexerRule = Record
    TokenKind: TTokenKind;
    Parser: TLexerRuleParser;
  End;

Function TLexer_Create(Const Source: String): PLexer;

Procedure TLexer_Destroy(Var Self: PLexer);

Procedure TLexer_AddRule(Var Self: PLexer; Const Rule: TLexerRule);

Function TLexer_GetNextToken(Var Self: PLexer): Boolean;

Function TLexer_IsToken(Var Self: PLexer; Const TokenKind: TTokenKind): Boolean;

Function TLexer_CompareNextToken(Var Self: PLexer;
  Const TokenKind: TTokenKind): Boolean;

Procedure TLexer_MoveNextChar(Var Self: PLexer);

Function TLexer_PeekNextChar(Var Self: PLexer): Char;

Implementation

Uses
  StringUtils;

Function TLexer_Create(Const Source: String): PLexer;
Begin
  New(Result);
  Result.RuleList := TList_Create(SizeOf(TLexerRule), 10);
  Result.Source := Source + #0;
  Result.CurrentPos := 0;
  Result.CurrentChar := '#';
  Result.CurrentToken.Kind := eUndefined;
End;

Function TLexer_GetNextToken(Var Self: PLexer): Boolean;
Var
  I: TSize;
Begin
  If Self.CurrentToken.Kind = eEof Then
  Begin
    Result := False;
    Exit;
  End;

  Repeat
    TLexer_MoveNextChar(Self);
  Until Not IsSpace(Self.CurrentChar);

  For I := 0 To Pred(Self.RuleList.Size) Do
  Begin
    If PLexerRule(TList_Get(Self.RuleList, I)).Parser(Self) Then
    Begin
      Result := (Self.CurrentToken.Kind <> eUndefined);
      Exit;
    End;
  End;

  Self.CurrentToken.StartPos := Self.CurrentPos;
  While (Not IsSpace(TLexer_PeekNextChar(Self))) And
    (TLexer_PeekNextChar(Self) <> #0) Do
  Begin
    TLexer_MoveNextChar(Self);
  End;
  Self.CurrentToken.Kind := eUndefined;
  Self.CurrentToken.Value := Copy(Self.Source, Self.CurrentToken.StartPos,
    Self.CurrentPos - Self.CurrentToken.StartPos + 1);
  Result := False;
End;

Procedure TLexer_Destroy(Var Self: PLexer);
Begin
  Dispose(Self.RuleList);
  Dispose(Self);
  Self := nil;
End;

Procedure TLexer_MoveNextChar(Var Self: PLexer);
Begin
  Inc(Self.CurrentPos);
  Self.CurrentChar := Self.Source[Self.CurrentPos];
End;

Function TLexer_PeekNextChar(Var Self: PLexer): Char;
Begin
  Result := Self.Source[Succ(Self.CurrentPos)];
End;

Procedure TLexer_AddRule(Var Self: PLexer; Const Rule: TLexerRule);
Begin
  TList_PushBack(Self.RuleList, @Rule);
End;

Function TLexer_IsToken(Var Self: PLexer; Const TokenKind: TTokenKind): Boolean;
Begin
  Result := (Self.CurrentToken.Kind = TokenKind);
End;

Function TLexer_CompareNextToken(Var Self: PLexer;
  Const TokenKind: TTokenKind): Boolean;
Begin
  TLexer_GetNextToken(Self);
  Result := TLexer_IsToken(Self, TokenKind);
End;

End.
