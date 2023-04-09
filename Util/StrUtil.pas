{ StringUtils.pas }
Unit StrUtil;

{$I define.inc}

Interface

Uses
  TypeDef;

Function IsSpace(Const Ch: Char): Boolean;
Function IsDigit(Const Ch: Char): Boolean;
Function IsHexDigit(Const Ch: Char): Boolean;
Function IsIdInitialChar(Const Ch: Char): Boolean;
Function IsIdChar(Const Ch: Char): Boolean;
Function Lower(Const Ch: Char): Char;
Function IsTermIdInitialChar(Const Ch: Char): Boolean;
Function IsNonTermIdInitialChar(Const Ch: Char): Boolean;
Function EscapeChar(Source: Char): Char;
Function CreateStr(Len: TSize): PChar;
Function ReallocStr(S: PChar; Len: TSize): PChar;
Procedure FreeStr(S: PChar);
Function SubStr(S: PChar; FromIndex: TSize; Len: TSize): PChar;
{$IFDEF FPC}
function strnew(p : pchar) : pchar;
{$ENDIF}

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF};

Function IsSpace(Const Ch: Char): Boolean;
Begin
  Result := Ch In [' ', #9, #10, #11, #12, #13];
End;

Function IsDigit(Const Ch: Char): Boolean;
Begin
  Result := Ch In ['0' .. '9'];
End;

Function IsHexDigit(Const Ch: Char): Boolean;
Begin
  Result := Ch In (['0' .. '9'] + ['a' .. 'f'] + ['A'..'F']);
End;

Function IsIdInitialChar(Const Ch: Char): Boolean;
Begin
  Result := Ch In (['_'] + ['a' .. 'z'] + ['A' .. 'Z']);
End;

Function IsIdChar(Const Ch: Char): Boolean;
Begin
  Result := Ch In (['_'] + ['a' .. 'z'] + ['A' .. 'Z'] + ['0' .. '9']);
End;

Function Lower(Const Ch: Char): Char;
Begin
  If (Ord(Ch) >= Ord('A')) And (Ord(Ch) <= Ord('Z')) Then
  Begin
    Result := Chr(Ord(Ch) - Ord('A') + Ord('a'));
  End
  Else
  Begin
    Result := Ch;
  End;
End;

Function IsTermIdInitialChar(Const Ch: Char): Boolean;
Begin
  Result := Ch In ['A' .. 'Z'];
End;

Function IsNonTermIdInitialChar(Const Ch: Char): Boolean;
Begin
  Result := Ch In ['a' .. 'z'];
End;

Function EscapeChar(Source: Char): Char;
Begin
  Case Source Of
    'a': Result := #7;
    'b': Result := #8;
    't': Result := #9;
    'n': Result := #10;
    'v': Result := #11;
    'f': Result := #12;
    'r': Result := #13;
    Else
      Result := Source;
  End;
End;

Function CreateStr(Len: TSize): PChar;
Begin
  {$IFDEF USE_STR_ALLOC}
  Result := StrAlloc(Len + 1);
  {$ELSE}
  GetMem(Result, (Len + 1) * SizeOf(Char));
  {$ENDIF}
  Result[0] := #0;
  Result[Len] := #0;
End;

Function ReallocStr(S: PChar; Len: TSize): PChar;
Begin
  {$IFDEF USE_STR_ALLOC}
  Result := StrAlloc(Len + 1);
  StrCopy(Result, S);
  StrDispose(S);
  {$ELSE}
  GetMem(Result, (Len + 1) * SizeOf(Char));
  strcopy(Result, S);
  FreeMem(S, (StrLen(S) + 1) * SizeOf(Char));
  {$ENDIF}
End;

Procedure FreeStr(S: PChar);
Begin
  {$IFDEF USE_STR_ALLOC}
  StrDispose(S);
  {$ELSE}
  FreeMem(S, (strlen(S) + 1) * SizeOf(Char));
  {$ENDIF}
End;

Function SubStr(S: PChar; FromIndex: TSize; Len: TSize): PChar;
Begin
  Result := CreateStr(Len);
  Move(S[FromIndex], Result[0], Len * SizeOf(Char));
  Result[Len] := #0;
End;

{$IFDEF FPC}
function strnew(p : pchar) : pchar;
var
  len : longint;
begin
  Result:=nil;
  if p=nil then
   exit;
  len:=strlen(p)+1;
  Result:=StrAlloc(Len);
  if Result<>nil then
   move(p^,Result^,len);
end;
{$ENDIF}


End.
