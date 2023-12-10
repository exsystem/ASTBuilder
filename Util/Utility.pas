Unit Utility;

{$I define.inc}

Interface

Uses
  TypeDef;

Procedure Swap(ElementSize: TSize; A: Pointer; B: Pointer);
{$IFDEF VINTAGE}
Function CompareMem(P1, P2: Pointer; Length: Integer): Boolean;
{$ENDIF}

Implementation

Procedure Swap(ElementSize: TSize; A: Pointer; B: Pointer);
Var
  C: Pointer;
Begin
  GetMem(C, ElementSize);
  Move(A^, C^, ElementSize);
  Move(B^, A^, ElementSize);
  Move(C^, A^, ElementSize);
  FreeMem(C, ElementSize);
End;

{$IFDEF VINTAGE}
Function CompareMem(P1, P2: Pointer; Length: Integer): Boolean;
Var
  I: Integer;
  B1, B2: ^Byte;
Begin
  B1 := P1;
  B2 := P2;
  Result := True;
  For I := 1 To Length Do
  Begin
    If B1^ <> B2^ Then
    Begin
      Result := False;
      Exit;
    End;
    Inc(B1);
    Inc(B2);
  End;
End;
{$ENDIF}

End.
