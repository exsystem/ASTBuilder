Unit StringUtils;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Function IsSpace(Const Ch: Char): Boolean;
Function IsDigit(Const Ch: Char): Boolean;
Function IsHexDigit(Const Ch: Char): Boolean;
Function Lower(Const Ch: Char): Char;

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

Function Lower(Const Ch: Char): Char;
Begin
  If (Ord(Ch) >= Ord('A')) And (Ord(Ch) <= Ord('Z')) Then
  Begin
    Result := Chr(Ord(Ch) - Ord('A'));
  End
  Else
  Begin
    Result := Ch;
  End;
End;

End.
