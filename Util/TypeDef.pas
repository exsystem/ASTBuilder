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

Function TNonTermRuleId_Make(Const Id: TNonTermRuleId): PNonTermRuleId;
Procedure TNonTermRuleId_Destroy(Var Self: PNonTermRuleId);
Function TTermRule_Make(Const Id: TTermRule): PTermRule;
Procedure TTermRule_Destroy(Var Self: PTermRule);

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

Function TNonTermRuleId_Make(Const Id: TNonTermRuleId): PNonTermRuleId;
Begin
  Result := PNonTermRuleId(TSize_Make(TSize(Id)));
End;

Procedure TNonTermRuleId_Destroy(Var Self: PNonTermRuleId);
Begin
  TSize_Destroy(PSize(Self));
End;

Function TTermRule_Make(Const Id: TTermRule): PTermRule;
Begin
  Result := PTermRule(TSize_Make(TSize(Id)));
End;

Procedure TTermRule_Destroy(Var Self: PTermRule);
Begin
  TSize_Destroy(PSize(Self));
End;

End.
