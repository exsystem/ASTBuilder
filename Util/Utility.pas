Unit Utility;

{$I define.inc}

Interface

Uses
  TypeDef;

Procedure Swap(ElementSize: TSize; A: Pointer; B: Pointer);

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

End.
