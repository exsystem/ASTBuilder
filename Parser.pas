Unit Parser;

{$I define.inc}
{.$DEFINE DEBUG}

Interface

Uses
  Lexer, List, TypeDef, ASTNode;

Type
  PParser = ^TParser;

  TSymbolFunc = Function(Parser: PParser; Var Ast: PAstNode): Boolean;

  TExpressionFunc = Function(Parser: PParser; Var Ast: PAstNode): Boolean;

  { TExpressionFuncArray = Array Of TExpressionFunc; }

  TParser = Record
    FLexer: PLexer;
    FTokenList: PList;
    FCurrentToken: TSize;
    MainProductionRule: TSymbolFunc;
    Ast: PAstNode;
    Error: PChar;
  End;

Function TParser_Create(Lexer: PLexer; ProductionRule: TSymbolFunc): PParser;

Function TParser_Parse(Self: PParser): Boolean;

Function TParser_GetNextToken(Self: PParser): Boolean;

Function TParser_IsToken(Self: PParser; TokenKind: TTokenKind): Boolean;

Function TParser_GetCurrentToken(Self: PParser): PToken;

Function TParser_TermByTokenKind(Self: PParser; TokenKind: TTokenKind): Boolean;

Function TParser_TermByGrammarTokenKind(Self: PParser; GrammarTokenKind: TGrammarTokenKind): Boolean;

Function TParser_Term(Self: PParser; TermRule: PChar): Boolean;

{
  Function TParser_Prod(Self: PParser; Var Ast: PAstNode;
  Rules: TExpressionFuncArray): Boolean;
}

Procedure TParser_Destroy(Self: PParser);

Implementation

  {$IFDEF DCC}
  {$IFDEF CLASSIC}
  Uses TypInfo, SysUtils, StrUtils;
  {$ELSE}
  Uses System.Rtti, SysUtils, StrUtils;
  {$ENDIF}
  {$ELSE}

Uses SysUtils, StrUtils;

  {$ENDIF}

Function TParser_Parse(Self: PParser): Boolean;
Var
  mTokenKind: TTokenKind;
Begin
  { NOTICE:                                                                    }
  { Since the main entry is here, the production rule procedural type must     }
  { accepting the AST parameter with the `Var` modifier, not `Out`!            }
  { Or resulting here with Self^.Ast be assigned with $5555.... eventually if  }
  { no parsing rule matched, with is not Nil($0000....), at least for          }
  { freepascal compilers with automatically initializing the Out parameters    }
  { with non-Nil ($5555....) values.                                           }
  mTokenKind.TokenKind := eEof;
  Result := Self^.MainProductionRule(Self, Self^.Ast) And TParser_TermByTokenKind(Self, mTokenKind);
End;

Function TParser_Create(Lexer: PLexer; ProductionRule: TSymbolFunc): PParser;
Begin
  New(Result);
  Result^.FLexer := Lexer;
  Result^.MainProductionRule := ProductionRule;
  Result^.FTokenList := TList_Create(SizeOf(TToken), 5);
  Result^.FCurrentToken := 0;
  Result^.Ast := nil;
  Result^.Error := strnew('');
End;

Procedure TParser_Destroy(Self: PParser);
Var
  I: TSize;
  mToken: PToken;
Begin
  For I := 0 To Self^.FTokenList^.Size - 1 Do
  Begin
    mToken := PToken(TList_Get(Self^.FTokenList, I));
    FreeStr(mToken^.Error);
    FreeStr(mToken^.Value);
    FreeStr(mToken^.Kind.TermRule);
  End;
  TList_Destroy(Self^.FTokenList);
  If Self^.Ast <> nil Then
  Begin
    Self^.Ast^.VMT^.Destory(Self^.Ast);
    Dispose(Self^.Ast);
  End;
  FreeStr(Self^.Error);
  Dispose(Self);
End;

Function TParser_TermByTokenKind(Self: PParser; TokenKind: TTokenKind): Boolean;
Begin
  If (Self^.FLexer^.NextPos > 1) And (Self^.FLexer^.CurrentToken.Kind.TokenKind =
    eUndefined) Then
  Begin
    { Low effeciency! Should stopped the parser immediately!
    { * Consider `E -> Term(A) or Term(B) or Term(C) ...`
    { * If an undefined token tested out during `Term(A)` with `False`         }
    {   returned, not because of not matching the `A`, you can not stop        }
    {   parsing E with this pattern of chaining terms together by `or`.        }
    { OR (BETTER CHOICE): Assuming the lexer has preprocessed already, so that }
    {   it is guaranteed no incorrect tokens during parsing^. So this IF-THEN  }
    {   code block should be completely removed!                               }
    Result := False;
    Exit;
  End;
  If TParser_GetNextToken(Self) Then
  Begin
    Result := TParser_IsToken(Self, TokenKind);
    If Not Result Then
    Begin
      Dec(Self^.FCurrentToken);
    End;
    Exit;
  End;
  Result := (TokenKind.TokenKind = eEof);
End;

Function TParser_TermByGrammarTokenKind(Self: PParser; GrammarTokenKind: TGrammarTokenKind): Boolean;
Var
  mTokenKind: TTokenKind;
Begin
  mTokenKind.TokenKind := GrammarTokenKind;
  mTokenKind.TermRule := StrNew('');
  Result := TParser_TermByTokenKind(Self, mTokenKind);
  FreeStr(mTokenKind.TermRule);
End;

Function TParser_Term(Self: PParser; TermRule: PChar): Boolean;
Var
  mTokenKind: TTokenKind;
Begin
  mTokenKind.TokenKind := eUserDefined;
  mTokenKind.TermRule := TermRule;
  Result := TParser_TermByTokenKind(Self, mTokenKind);
End;

(*
procedure InterlockedIncStringRefCount(p: pointer);
asm
  mov eax,[eax]
  test eax,eax
  jz @done
  mov ecx,[eax-8]
  inc ecx
  jz @done //Do not touch constant strings^.
  lock inc dword ptr[eax-8];
@done:
end;
*)

Function TParser_GetNextToken(Self: PParser): Boolean;
Var
{$IFDEF DEBUG}
  t: String;
{$ENDIF}
  mToken: PToken;
Begin
  If Self^.FCurrentToken = Self^.FTokenList^.Size Then
  Begin
    Result := TLexer_GetNextToken(Self^.FLexer);
    If Result Then
    Begin
      Inc(Self^.FCurrentToken);
      (*
      InterlockedIncStringRefCount(@Self^.FLexer^.CurrentToken^.Value);  // PATCHED LINE
      TList_PushBack(Self^.FTokenList, @(Self^.FLexer^.CurrentToken));
      *)
      mToken := TList_EmplaceBack(Self^.FTokenList); { USE EMPLACE }
      mToken^ := Self^.FLexer^.CurrentToken;
      mToken^.Error := StrNew(Self^.FLexer^.CurrentToken.Error);
      mToken^.Value := StrNew(Self^.FLexer^.CurrentToken.Value);
      mToken^.Kind.TermRule := StrNew(Self^.FLexer^.CurrentToken.Kind.TermRule);
      {$IFDEF DEBUG}
      {$IFDEF FPC}
      WriteStr(t, TParser_GetCurrentToken(Self)^.Kind);
      {$ELSE}
      t := TRttiEnumerationType.GetName(TParser_GetCurrentToken(Self)^.Kind.TokenKind);
      {$ENDIF}
      Writeln('> TOKEN: [' + TParser_GetCurrentToken(Self)^.Value + '] is ' + t);
      {$ENDIF}
    End;
  End
  Else
  Begin
    Result := True;
    Inc(Self^.FCurrentToken);
  End;
End;

Function TParser_IsToken(Self: PParser; TokenKind: TTokenKind): Boolean;
Begin
  Result := (TParser_GetCurrentToken(Self)^.Kind.TokenKind = TokenKind.TokenKind);
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
  Result := PToken(TList_Get(Self^.FTokenList, Self^.FCurrentToken - 1));
End;

End.
