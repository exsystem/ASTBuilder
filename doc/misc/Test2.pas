Unit Test2;

Interface

Type
  PParent = ^TParent;

  TParent = Record
    p: String;
  End;

  PChild = ^TChild;

  TChild = Record
    Parent: TParent;
    c: Array[0..1023] Of Byte;
    str1: String;
  End;

  POther = ^TOther;

  TOther = Record
    Data: Array[0..31] Of Byte;
  End;

Procedure foo(Var p);

Implementation

Uses
  SysUtils;

Procedure Test;
Var
  c: PChild;
  p: PParent;
  b: Byte;
Begin
  New(c);
  c.Parent.p := '12345678';
  c.str1 := 'hello!';
  FillChar(c.c[0], 1024, $55);
  p := PParent(c);
  For b In c.c Do
  Begin
    Write(Format('%x ', [b]));
    WriteLn(c.str1);
  End;
  foo(p);
  // MEMORY LEAKED! c.str1 may not disposed, if using Delphi compiler!
End;

Procedure foo(Var p);
Begin
  If Pointer(p) <> nil Then
  Begin
    Dispose(POther(p));
    // 此处会不会按照PChild的占用内存大小回收内存呢？
    //PParent(p) := nil;
  End;
End;

End.
