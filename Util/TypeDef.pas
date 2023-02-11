Unit TypeDef;

{$I define.inc}

Interface

Type
  {$IFDEF VER150}
  UIntPtr = Cardinal;
  {$ENDIF}

  PSize = ^TSize;
  TSize = UIntPtr;

Implementation

End.
