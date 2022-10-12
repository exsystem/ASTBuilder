Unit Lexer;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  List, TypeDef;

Type
  TTokenKind = (eUndefined, eNot, eAnd, eOr, eXor, eAdd, eSub, eMul,
    eSlash, eMod, eShl, eShr, eEqual, eNotEqual, eLT, eLE, eGT, eGE,
    eLParent, eRParent, eAs, eIs, eIn, eAt, eCaret, eNum, eEof);

  PToken = ^TToken;

  TToken = Record
    Kind: TTokenKind;
    Error: String;
    Value: String;
    StartPos: TSize;
  End;

  PLexer = ^TLexer;

  TLexer = Record
    RuleList: PList;
    Source: String;
    NextPos: TSize;
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

Procedure TLexer_Forward(Var Self: PLexer; Const Step: TSize = 1);

Function TLexer_PeekNextChar(Var Self: PLexer): Char;

Function TLexer_PeekNextWord(Var Self: PLexer; Const NextWord: String): Boolean;

Implementation

Uses
  StringUtils, SysUtils;

Function TLexer_Create(Const Source: String): PLexer;
Begin
  New(Result);
  Result.RuleList := TList_Create(SizeOf(TLexerRule), 10);
  Result.Source := Source + #0;
  Result.NextPos:= 1;
  Result.CurrentToken.Kind := eUndefined;
End;

Function TLexer_GetNextToken(Var Self: PLexer): Boolean;
Var
  I: TSize;
  mRule: PLexerRule;
Begin
  If Self.CurrentToken.Kind = eEof Then
  Begin
    Result := False;
    Exit;
  End;

  while IsSpace(TLexer_PeekNextChar(Self)) do
  begin
    TLexer_Forward(Self);
  end;
  
  For I := 0 To Pred(Self.RuleList.Size) Do
  Begin
    mRule := PLexerRule(TList_Get(Self.RuleList, I));
    Self.CurrentToken.Error := '';
    If mRule.Parser(Self) Then
    Begin
      Result := (Self.CurrentToken.Error = '');
      If Result Then
      Begin
        Self.CurrentToken.Kind := mRule.TokenKind;
      End
      Else
      Begin
        Self.CurrentToken.Kind := eUndefined;
      End;
      Exit;
    End;
  End;

  Self.CurrentToken.StartPos := Self.NextPos;
  While (Not IsSpace(TLexer_PeekNextChar(Self))) And
    (TLexer_PeekNextChar(Self) <> #0) Do
  Begin
    TLexer_Forward(Self);
  End;
  Self.CurrentToken.Kind := eUndefined;
  Self.CurrentToken.Error := 'Illegal token.';
  Self.CurrentToken.Value := Copy(Self.Source, Self.CurrentToken.StartPos,
    Self.NextPos - Self.CurrentToken.StartPos);
  Result := False;
End;

Procedure TLexer_Destroy(Var Self: PLexer);
Begin
  Dispose(Self.RuleList);
  Dispose(Self);
  Self := nil;
End;

Procedure TLexer_Forward(Var Self: PLexer; Const Step: TSize = 1);
Begin
  Inc(Self.NextPos, Step);
End;

Function TLexer_PeekNextChar(Var Self: PLexer): Char;
Begin
  Result := Self.Source[Self.NextPos];
End;

Function TLexer_PeekNextWord(Var Self: PLexer; Const NextWord: String): Boolean;
Begin
  Result := CompareMem(@Self.Source[Self.NextPos], @NextWord[1], Length(NextWord));
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
