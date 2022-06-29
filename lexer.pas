Unit Lexer;

{$MODE DELPHI}

Interface

Uses
  List;

Type
  TTokenKind = (
    eUndefined,
    eAdd, eSub, eMul, eDiv,
    eLParent, eRParent,
    eNum,
    eEof
    );

  TToken = Record
    Kind: TTokenKind;
    Value: String;
    StartPos: UInt32;
  End;

  PLexer = ^TLexer;

  TLexer = Record
    RuleList: PList;
    Source: String;
    CurrentPos: UInt32;
    CurrentChar: Char;
  End;

  TLexerRuleParser = Function(Lexer: PLexer; Out Token: TToken): Boolean;

  PLexerRule = ^TLexerRule;

  TLexerRule = Record
    TokenKind: TTokenKind;
    Parser: TLexerRuleParser;
  End;

Function TLexer_Create(Const Source: String): PLexer;
Procedure TLexer_Destroy(Var Self: PLexer);
Procedure TLexer_AddRule(Var Self: PLexer; Const Rule: TLexerRule);
Function TLexer_GetNextToken(Var Self: PLexer; Out Token: TToken): Boolean;
Procedure TLexer_MoveNextChar(Var Self: PLexer);
Function TLexer_PeekNextChar(Var Self: PLexer): Char;

Implementation

Uses
  StringUtils, TypeDef;

Function TLexer_Create(Const Source: String): PLexer;
Begin
  New(Result);
  Result.RuleList := TList_Create(SizeOf(TLexerRule), 10);
  Result.Source := Source + #0;
  Result.CurrentPos := 0;
  Result.CurrentChar := '#';
End;

Function TLexer_GetNextToken(Var Self: PLexer; Out Token: TToken): Boolean;
Var
  I: TSize;
Begin
  Repeat
    TLexer_MoveNextChar(Self);
  Until Not IsSpace(Self.CurrentChar);

  For I := 0 To Pred(Self.RuleList.Size) Do
  Begin
    If PLexerRule(TList_Get(Self.RuleList, I)).Parser(Self, Token) Then
    Begin
      Exit(True);
    End;
  End;

  Token.StartPos := Self.CurrentPos;
  While (Not IsSpace(TLexer_PeekNextChar(Self))) And (TLexer_PeekNextChar(Self) <> #0) Do
  Begin
    TLexer_MoveNextChar(Self);
  End;
  Token.Kind := eUndefined;
  Token.Value := Copy(Self.Source, Token.StartPos, Self.CurrentPos - Token.StartPos + 1);
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

End.
