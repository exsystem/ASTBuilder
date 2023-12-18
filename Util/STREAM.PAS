Unit Stream;

{$I define.inc}

Interface

Uses
  TypeDef;

Type
  PStream_VMT = ^TStream_VMT;

  PStream = ^TStream;

  TStream_Destroy_Proc= procedure(Const Self: PStream);
  TStream_GetLength_Proc= Function(Const Self: PStream): TSize;
  TStream_GetPosition_Proc = Function(Const Self: PStream): TSize;
  TStream_SetPosition_Proc = Procedure(Const Self: PStream; Value: TSize);
  TStream_Forward_Proc = Function(Const Self: PStream; Offset: TSize): Boolean;
  TStream_Rewind_Proc = Function(Const Self: PStream; Offset: TSize): Boolean;
  TStream_IsEof_Proc = Function(Const Self: PStream): Boolean;
  TStream_Read_Proc = Function(Const Self: PStream; Var Data;
    Const Length: TSize): TSize;

  TStream_VMT = Record
    Destroy: TStream_Destroy_Proc;
    GetLength: TStream_GetLength_Proc;
    GetPosition: TStream_GetPosition_Proc;
    SetPosition: TStream_SetPosition_Proc;
    Forward: TStream_Forward_Proc;
    Rewind: TStream_Rewind_Proc;
    IsEof: TStream_IsEof_Proc;
    Read: TStream_Read_Proc;
  End;

  TStream = Record
    VMT: PStream_VMT;
  End;

  PFileStream = ^TFileStream;

  TFileStream = Record
    Parent: TStream;
    FFile: File {Of Char};
  End;

Procedure TFileStream_Create(Var Self: PFileStream; Filename: String);
Procedure TFileStream_Destroy(Const Self: PStream);
Function TFileStream_GetLength(Const Self: PStream): TSize;
Function TFileStream_GetPosition(Const Self: PStream): TSize;
Procedure TFileStream_SetPosition(Const Self: PStream; Value: TSize);
Function TFileStream_Forward(Const Self: PStream; Offset: TSize): Boolean;
Function TFileStream_Rewind(Const Self: PStream; Offset: TSize): Boolean;
Function TFileStream_IsEof(Const Self: PStream): Boolean;
Function TFileStream_Read(Const Self: PStream; Var Data;
  Const Length: TSize): TSize;

Implementation

Var
  mTFileStream_VMT: TStream_VMT;

Procedure TFileStream_Create(Var Self: PFileStream; Filename: String);
Begin
  New(Self); { Final }
  Self^.Parent.VMT := @mTFileStream_VMT;

  AssignFile(Self^.FFile, Filename);
  Reset(Self^.FFile, SizeOf(Char));
  {$IFDEF UTF16_TEXT}
  Seek(Self^.FFile, 1);
  {$ENDIF}
End;

Procedure TFileStream_Destroy(Const Self: PStream);
Begin
  CloseFile(PFileStream(Self)^.FFile);
End;

Function TFileStream_GetLength(Const Self: PStream): TSize;
Begin
  Result := FileSize(PFileStream(Self)^.FFile) {$IFDEF UTF16_TEXT} - 1 {$ENDIF};
End;

Function TFileStream_GetPosition(Const Self: PStream): TSize;
Begin
  Result := FilePos(PFileStream(Self)^.FFile) {$IFDEF UTF16_TEXT} - 1 {$ENDIF};
End;

Procedure TFileStream_SetPosition(Const Self: PStream; Value: TSize);
Begin
  Seek(PFileStream(Self)^.FFile, Value {$IFDEF UTF16_TEXT} + 1 {$ENDIF});
End;

Function TFileStream_Forward(Const Self: PStream; Offset: TSize): Boolean;
Begin
  Seek(PFileStream(Self)^.FFile, FilePos(PFileStream(Self)^.FFile) + Offset);
  Result := True;
End;

Function TFileStream_Rewind(Const Self: PStream; Offset: TSize): Boolean;
Begin
  Seek(PFileStream(Self)^.FFile, FilePos(PFileStream(Self)^.FFile) - Offset);
  Result := True;
End;

Function TFileStream_IsEof(Const Self: PStream): Boolean;
Begin
  Result := EOF(PFileStream(Self)^.FFile);
End;

Function TFileStream_Read(Const Self: PStream; Var Data;
  Const Length: TSize): TSize;
{$IFDEF WIN64}
Var
  mResult: Integer;
{$ENDIF}
Begin
  {$IFDEF FPC}
  BlockRead(PFileStream(Self)^.FFile, Data, Int64(Length), Int64(Result));
  {$ELSE}
  {$IFDEF WIN64}
  BlockRead(PFileStream(Self)^.FFile, Data, Integer(Length), mResult);
  Result := mResult;
  {$ELSE}
  BlockRead(PFileStream(Self)^.FFile, Data, Length, Result);
  {$ENDIF}
  {$ENDIF}
End;

Begin
  mTFileStream_VMT.Destroy :=  TFileStream_Destroy;
  mTFileStream_VMT.GetLength:= TFileStream_GetLength;
  mTFileStream_VMT.GetPosition := TFileStream_GetPosition;
  mTFileStream_VMT.SetPosition := TFileStream_SetPosition;
  mTFileStream_VMT.Forward := TFileStream_Forward;
  mTFileStream_VMT.Rewind := TFileStream_Rewind;
  mTFileStream_VMT.IsEof := TFileStream_IsEof;
  mTFileStream_VMT.Read := TFileStream_Read;
End.
