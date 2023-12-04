Unit PARSER;

{$I define.inc}
{.$DEFINE DEBUG}

Interface

Uses
  Lexer, List, TypeDef, ASTNode;

Type
  PParser = ^TParser;
  PParser_VMT = ^TParser_VMT;

  TParser_Destroy_Proc = procedure(Const Self: PParser);
  TParser_IsTokenKindUndefined_Proc = function(Const TokenKind: Pointer): Boolean;
  TParser_IsTokenKindEof_Proc = function(Const TokenKind: Pointer): Boolean;
  TParser_CopyTokenKind_Proc = function(Const TokenKind: Pointer): Pointer;
  TParser_CompareTokenKind_Proc = function(Self: PParser; Const LHS: Pointer; Const RHS: Pointer): Boolean;

  TParser_VMT = record
    Destroy: TParser_Destroy_Proc;
    IsTokenKindUndefined: TParser_IsTokenKindUndefined_Proc;
    IsTokenKindEof: TParser_IsTokenKindEof_Proc;
    CopyTokenKind: TParser_CopyTokenKind_Proc;
    CompareTokenKind: TParser_CompareTokenKind_Proc;
  end;

  TParser = Record
    VMT: PParser_VMT;
    FLexer: PLexer;
    FTokenList: PList;
    FCurrentToken: TSize;
    Error: PChar;
  End;

procedure TParser_Create(Var Self: PParser; Lexer: PLexer);

Function TParser_GetNextToken(Self: PParser): Boolean;

Function TParser_IsToken(Self: PParser; TokenKind: Pointer): Boolean;

Function TParser_GetCurrentToken(Self: PParser): PToken;

Function TParser_Term(Self: PParser; TokenKind: Pointer): Boolean;

Procedure TParser_Destroy(Self: PParser);

Implementation

  {$IFDEF DCC}
  {$IFDEF CLASSIC}
  Uses TypInfo, SysUtils, StrUtil;
  {$ELSE}
  Uses System.Rtti, SysUtils, StrUtil;
  {$ENDIF}
  {$ELSE}

Uses SysUtils, StrUtil;

  {$ENDIF}

Procedure TParser_Create(Var Self: PParser; Lexer: PLexer);
Begin
  Self^.FLexer := Lexer;
  Self^.FTokenList := TList_Create(SizeOf(TToken), 5);
  Self^.FCurrentToken := 0;
  Self^.Error := strnew('');
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
  End;
  TList_Destroy(Self^.FTokenList);
  FreeStr(Self^.Error);
End;

Function TParser_Term(Self: PParser; TokenKind: Pointer): Boolean;
Begin
  If (TLexer_GetNextPos(Self^.FLexer) > 1) And Self^.VMT^.IsTokenKindUndefined(Self^.FLexer^.CurrentToken.Kind) Then
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
  Result := Self^.VMT^.IsTokenKindUndefined(TokenKind);
End;

Function TParser_GetNextToken(Self: PParser): Boolean;
Var
(*
{$IFDEF DEBUG}
  t: String;
{$ENDIF}
*)
  mToken: PToken;
Begin
  If Self^.FCurrentToken = Self^.FTokenList^.Size Then
  Begin
    Result := Self^.FLexer^.VMT^.GetNextToken(Self^.FLexer);
    If Result Then
    Begin
      Inc(Self^.FCurrentToken);
      mToken := TList_EmplaceBack(Self^.FTokenList); { USE EMPLACE }
      mToken^ := Self^.FLexer^.CurrentToken;
      mToken^.Error := StrNew(Self^.FLexer^.CurrentToken.Error);
      mToken^.Value := StrNew(Self^.FLexer^.CurrentToken.Value);
      mToken^.Kind := Self^.VMT^.CopyTokenKind(Self^.FLexer^.CurrentToken.Kind);
      (*
      {$IFDEF DEBUG}
      {$IFDEF FPC}
      WriteStr(t, TParser_GetCurrentToken(Self)^.Kind);
      {$ELSE}
      t := TRttiEnumerationType.GetName(TParser_GetCurrentToken(Self)^.Kind.TokenKind);
      {$ENDIF}
      Writeln('> TOKEN: [' + TParser_GetCurrentToken(Self)^.Value + '] is ' + t);
      {$ENDIF}
      *)
    End;
  End
  Else
  Begin
    Result := True;
    Inc(Self^.FCurrentToken);
  End;
End;

Function TParser_IsToken(Self: PParser; TokenKind: Pointer): Boolean;
Begin
  Result := Self^.VMT^.CompareTokenKind(Self, TParser_GetCurrentToken(Self)^.Kind, TokenKind);
End;

Function TParser_GetCurrentToken(Self: PParser): PToken;
Begin
  Result := PToken(TList_Get(Self^.FTokenList, Self^.FCurrentToken - 1));
End;

End.
