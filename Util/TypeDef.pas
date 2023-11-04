Unit TypeDef;

{$I define.inc}

Interface

Type
  {$IFDEF TPC}
  Cardinal = Word;
  {$ENDIF}

  {$IFDEF CLASSIC}
  UIntPtr = Cardinal;
  PByte = ^Byte;
  PBoolean = ^Boolean;
  PPChar = ^PChar;
  {$ENDIF}

  PSize = ^TSize;
  TSize = UIntPtr;

  { TODO Allocator? }
  TElementDestructor = Procedure(Const Element: Pointer);

Implementation

End.
