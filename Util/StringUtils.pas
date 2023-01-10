Unit StringUtils;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Function IsSpace(Const Ch: Char): Boolean;
Function IsDigit(Const Ch: Char): Boolean;
Function IsHexDigit(Const Ch: Char): Boolean;
Function IsIdInitialChar(Const Ch: Char): Boolean;
Function IsIdChar(Const Ch: Char): Boolean;
Function Lower(Const Ch: Char): Char;
Function IsTermIdInitialChar(Const Ch: Char): Boolean;
Function IsNonTermIdInitialChar(Const Ch: Char): Boolean;

Implementation

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

End.
