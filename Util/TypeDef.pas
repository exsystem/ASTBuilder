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

  { 0: invalid, aka '' }
  { 1: root node, aka '*' }
  TNonTermRuleId = TSize;
  PNonTermRuleId = ^TNonTermRuleId;

  { 0: undefined, aka '' }
  { 1: EOF }
  TTermRule = TSize;
  PTermRule = ^TTermRule;

Function TSize_Make(Const Id: TSize): PSize;
Procedure TSize_Destroy(Var Self: PSize);

Implementation

Function TSize_Make(Const Id: TSize): PSize;
Begin
  New(Result);
  Result^ := Id;
End;

Procedure TSize_Destroy(Var Self: PSize);
Begin
  Dispose(Self);
  Self := nil;
End;

End.
