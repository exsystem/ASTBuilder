Unit Lexer;

{$I define.inc}
Interface

Uses
  TypeDef, Stream, GrmrNode;

Type
  PToken = ^TToken;
  PLexer = ^TLexer;
  PLexer_VMT = ^TLexer_VMT;

  TToken = Record
    Error: PChar;
    Value: PChar;
    StartPos: TSize;
    Kind: Pointer;
  End;
  TLexer_Destroy_Proc = Procedure(Self: PLexer);
  TLexer_IsToken_Proc = Function(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
  TLexer_GetNextToken_Proc = Function(Var Self: PLexer): Boolean;

  TLexer_VMT = Record
    Destory: TLexer_Destroy_Proc;
    IsToken: TLexer_IsToken_Proc;
    GetNextToken: TLexer_GetNextToken_Proc;
  End;

  TLexer = Record
    VMT: PLexer_VMT;
    FCaseSensitive: Boolean;
    FStream: PStream;
    CurrentToken: TToken;
  End;

Procedure TLexer_Create(Var Self: PLexer; Const Source: PStream;
  Const CaseSensitive: Boolean);
Procedure TLexer_Destroy(Var Self: PLexer);
Function TLexer_CompareNextToken(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
Procedure TLexer_Forward(Var Self: PLexer; Const Step: TSize);
Function TLexer_PeekNextChar(Var Self: PLexer): Char;
Function TLexer_PeekNextWord(Var Self: PLexer; Const NextWord: PChar): Boolean;
Function TLexer_GetNextChar(Var Self: PLexer): Char;
Procedure TLexer_Retract(Var Self: PLexer; Const Step: TSize);
Function TLexer_GetNextPos(Var Self: PLexer): TSize;
Procedure TLexer_FetchNextToken(Var Self: PLexer; Length: TSize);

Implementation

Uses
  SysUtils, StrUtil, TrmRNode{$IFDEF USE_STRINGS}, strings{$ENDIF};

Procedure TLexer_Create(Var Self: PLexer; Const Source: PStream;
  Const CaseSensitive: Boolean);
Begin
  Self^.FCaseSensitive := CaseSensitive;
  Source^.VMT^.SetPosition(Source, 0);
  Self^.FStream := Source;
  Self^.CurrentToken.Value := strnew('');
  Self^.CurrentToken.Error := strnew('');
End;

Procedure TLexer_Destroy(Var Self: PLexer);
Begin
  FreeStr(Self^.CurrentToken.Error);
  FreeStr(Self^.CurrentToken.Value);
  Self^.FStream^.VMT^.Destroy(Self^.FStream);
End;

Procedure TLexer_Forward(Var Self: PLexer; Const Step: TSize);
Begin
  Self^.FStream^.VMT^.Forward(Self^.FStream, Step);
End;

Function TLexer_PeekNextChar(Var Self: PLexer): Char;
Begin
  If Self^.FStream^.VMT^.IsEof(Self^.FStream) Then
  Begin
    Result := #0;
    Exit;
  End;
  Self^.FStream^.VMT^.Read(Self^.FStream, Result, 1);
  Self^.FStream^.VMT^.Rewind(Self^.FStream, 1);
End;

Function TLexer_GetNextChar(Var Self: PLexer): Char;
Begin
  Self^.FStream^.VMT^.Read(Self^.FStream, Result, 1);
End;

Function TLexer_PeekNextWord(Var Self: PLexer; Const NextWord: PChar): Boolean;
Var
  I: TSize;
  mNextWordLength: TSize;
  {$IFNDEF CLASSIC}
  mSourceNextWord: PChar;
  {$ENDIF}
Begin
  mNextWordLength := StrLen(NextWord);
  If Self^.FStream^.VMT^.GetPosition(Self^.FStream) + mNextWordLength >
    Self^.FStream^.VMT^.GetLength(Self^.FStream) Then
  Begin
    Result := False;
    Exit;
  End;
  If Not Self^.FCaseSensitive Then
  Begin
    Result := True;
    For I := 0 To mNextWordLength - 1 Do
    Begin
      If Lower(NextWord[I]) <> Lower(TLexer_GetNextChar(Self)) Then
      Begin
        Result := False;
        Self^.FStream^.VMT^.Rewind(Self^.FStream, Succ(I));
        Exit;
      End;
    End;
    Self^.FStream^.VMT^.Rewind(Self^.FStream, mNextWordLength);
    Exit;
  End;
  {$IFNDEF CLASSIC}
  GetMem(mSourceNextWord, mNextWordLength * SizeOf(Char));
  Self^.FStream^.VMT^.Read(Self^.FStream, mSourceNextWord^, mNextWordLength);
  Self^.FStream^.VMT^.Rewind(Self^.FStream, mNextWordLength);
  Result := CompareMem(mSourceNextWord, NextWord, mNextWordLength * SizeOf(Char));
  FreeMem(mSourceNextWord);
  If Result Then
  Begin
    Exit;
  End;
  {$ENDIF}
  For I := 0 To mNextWordLength - 1 Do
  Begin
    If NextWord[I] <> TLexer_GetNextChar(Self) Then
    Begin
      Result := False;
      Self^.FStream^.VMT^.Rewind(Self^.FStream, Succ(I));
      Exit;
    End;
  End;
  Self^.FStream^.VMT^.Rewind(Self^.FStream, mNextWordLength);
  Result := True;
End;

Function TLexer_CompareNextToken(Var Self: PLexer; Const TokenKind: Pointer): Boolean;
Begin
  Self^.VMT^.GetNextToken(Self);
  Result := Self^.VMT^.IsToken(Self, TokenKind);
End;

Procedure TLexer_Retract(Var Self: PLexer; Const Step: TSize);
Begin
  Self^.FStream^.VMT^.Rewind(Self^.FStream, Step);
End;

Function TLexer_GetNextPos(Var Self: PLexer): TSize;
Begin
  Result := Self^.FStream^.VMT^.GetPosition(Self^.FStream);
End;

Procedure TLexer_FetchNextToken(Var Self: PLexer; Length: TSize);
Begin
  FreeStr(Self^.CurrentToken.Value);
  Self^.CurrentToken.Value := CreateStr(Length);
  Self^.FStream^.VMT^.SetPosition(Self^.FStream, Self^.CurrentToken.StartPos);
  Self^.FStream^.VMT^.Read(Self^.FStream, Self^.CurrentToken.Value^, Length);
End;

End.
