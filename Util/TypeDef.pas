Unit TypeDef;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Type
  {$IFDEF VER150}
  UIntPtr = Cardinal;
  {$ENDIF}

  PSize = ^TSize;
  TSize = UIntPtr;

Implementation

End.
