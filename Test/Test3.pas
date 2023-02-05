Unit Test3;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Type
  TTest = Record
    MyInt: Integer;
    MyString: String;
  End;

Procedure TestStr();

Procedure Test();

Implementation

Uses
  List, TypeDef, SysUtils;

Procedure TestStr();
Var
  mList: PList; // of string
  I: TSize;
  mItem: String;
Begin
  mList := TList_Create(SizeOf(String), 1);
  mItem := '1111';
  TList_PushBack(mList, @mItem);
  mItem := '2222';
  TList_PushBack(mList, @mItem);
  mItem := '3333';
  TList_PushBack(mList, @mItem);
  For I := 0 To mList.Size - 1 Do
  Begin
    mItem := String(TList_Get(mList, I)^);
    WriteLn(mItem);
    mItem := 'foo' + mItem;
    TList_Set(mList, I, @mItem);
  End;
  For I := 0 To mList.Size - 1 Do
  Begin
    mItem := String(TList_Get(mList, I)^);
    mItem := 'foo' + mItem;
    WriteLn(mItem);
  End;
  TList_Destroy(mList);
  ReadLn;
End;

Procedure Test();
Var
  mList: PList; // of TTest
  I: TSize;
  mItem: TTest;

Begin
  TestStr();

  mList := TList_Create(SizeOf(TTest), 1);

  mItem.MyInt := 11;
  mItem.MyString := 'abc';
  TList_PushBack(mList, @mItem);

  mItem.MyInt := 22;
  mItem.MyString := 'def';
  TList_PushBack(mList, @mItem);

  mItem.MyInt := 33;
  mItem.MyString := 'ghi';
  TList_PushBack(mList, @mItem);

  For I := 0 To mList.Size - 1 Do
  Begin
    mItem := TTest(TList_Get(mList, I)^);
    WriteLn(IntToStr(mItem.MyInt) + ', ' + mItem.MyString);
    mItem.MyString := 'foo' + mItem.MyString;
    TList_Set(mList, I, @mItem);
  End;
  For I := 0 To mList.Size - 1 Do
  Begin
    mItem := TTest(TList_Get(mList, I)^);
    mItem.MyString := 'foo' + mItem.MyString;
    WriteLn(IntToStr(mItem.MyInt) + ', ' + mItem.MyString);
  End;
  TList_Destroy(mList);
  ReadLn;
End;

End.
