{ Unit GrammarParser; }
Unit GPARSER;

{$I define.inc}
{.$DEFINE DEBUG}

Interface

Uses
  Lexer, GLexer, Parser, List, TypeDef, ASTNode;

Type
  PGrammarParser = ^TGrammarParser;

  TSymbolFunc = Function(Parser: PParser; Var Ast: PAstNode): Boolean;

  TExpressionFunc = Function(Parser: PParser; Var Ast: PAstNode): Boolean;

  TGrammarParser = Record
    Parent: TParser;
    MainProductionRule: TSymbolFunc;
    Ast: PAstNode;
  End;

Procedure TGrammarParser_Create(Var Self: PGrammarParser; Lexer: PLexer;
  ProductionRule: TSymbolFunc);

Procedure TGrammarParser_Destroy(Const Self: PParser);

Function TGrammarParser_IsTokenKindUndefined(Const TokenKind: Pointer): Boolean;

Function TGrammarParser_IsTokenKindEof(Const TokenKind: Pointer): Boolean;

Function TGrammarParser_CopyTokenKind(Const TokenKind: Pointer): Pointer;

Function TGrammarParser_CompareTokenKind(Self: PParser; Const LHS: Pointer;
  Const RHS: Pointer): Boolean;

Function TGrammarParser_Parse(Const Self: PGrammarParser): Boolean;

Function TGrammarParser_Term(Parser: PParser; TokenKind: TGrammarTokenKind): Boolean;

Implementation

Uses
  {$IFDEF DCC}
  {$IFDEF CLASSIC}
  TypInfo, 
  {$ELSE}
  System.Rtti,
  {$ENDIF}
  StrUtil,
  {$ENDIF}
  SysUtils, GRMRNODE, Trie;

Var
  mTGrammarParser_VMT: TParser_VMT;

Procedure TGrammarParser_Create(Var Self: PGrammarParser; Lexer: PLexer;
  ProductionRule: TSymbolFunc);
Begin
  New(Self); { Final }
  TParser_Create(PParser(Self), Lexer);

  Self^.Parent.VMT := @mTGrammarParser_VMT;

  Self^.MainProductionRule := ProductionRule;
  Self^.Ast := nil;
End;

Procedure TGrammarParser_Destroy(Const Self: PParser);
Var
  I: TSize;
  mToken: PToken;
  mSelf: PGrammarParser;
Begin
  For I := 0 To Self^.FTokenList^.Size - 1 Do
  Begin
    mToken := PToken(TList_Get(Self^.FTokenList, I));
    Dispose(PGrammarTokenKind(mToken^.Kind));
  End;
  mSelf := PGrammarParser(Self);
  If mSelf^.Ast <> nil Then
  Begin
    mSelf^.Ast^.VMT^.Destory(mSelf^.Ast);
    Dispose(mSelf^.Ast);
  End;
  TParser_Destroy(Self);
End;

Function TGrammarParser_IsTokenKindUndefined(Const TokenKind: Pointer): Boolean;
Begin
  Result := (PGrammarTokenKind(TokenKind)^ = eUndefined);
End;

Function TGrammarParser_IsTokenKindEof(Const TokenKind: Pointer): Boolean;
Begin
  Result := (PGrammarTokenKind(TokenKind)^ = eEof);
End;

Function TGrammarParser_CopyTokenKind(Const TokenKind: Pointer): Pointer;
Begin
  New(PGrammarTokenKind(Result));
  PGrammarTokenKind(Result)^ := PGrammarTokenKind(TokenKind)^;
End;

Function TGrammarParser_CompareTokenKind(Self: PParser; Const LHS: Pointer;
  Const RHS: Pointer): Boolean;
Begin
  Result := (PGrammarTokenKind(LHS)^ = PGrammarTokenKind(RHS)^);
End;

Function TGrammarParser_Parse(Const Self: PGrammarParser): Boolean;
Var
  mTokenKind: TGrammarTokenKind;
Begin
  mTokenKind := eEof;
  Result := Self^.MainProductionRule(PParser(Self), Self^.Ast) And
    TParser_Term(PParser(Self), @mTokenKind);
End;

Function TGrammarParser_Term(Parser: PParser; TokenKind: TGrammarTokenKind): Boolean;
Begin
  Result := TParser_Term(Parser, Pointer(@TokenKind));
End;

Begin
  mTGrammarParser_VMT.Destroy := TGrammarParser_Destroy;
  mTGrammarParser_VMT.IsTokenKindUndefined := TGrammarParser_IsTokenKindUndefined;
  mTGrammarParser_VMT.IsTokenKindEof := TGrammarParser_IsTokenKindEof;
  mTGrammarParser_VMT.CopyTokenKind := TGrammarParser_CopyTokenKind;
  mTGrammarParser_VMT.CompareTokenKind := TGrammarParser_CompareTokenKind;
End.
