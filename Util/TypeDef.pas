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

  { 0: undefined, aka '' }
  { 1: EOF }
  TTermRule = TSize;
  PTermRule = ^TTermRule;

Function TTermRule_Make(Const Id: TSize): PTermRule;
Procedure TTermRule_Destroy(Var Self: PTermRule);

Implementation

Function TTermRule_Make(Const Id: TSize): PTermRule;
Begin
  New(Result);
  Result^ := Id;
End;

Procedure TTermRule_Destroy(Var Self: PTermRule);
Begin
  Dispose(Self);
  Self := nil;
End;

End.
