Unit Stream;

{$I define.inc}

Interface

Uses
  TypeDef;

Type
  PStream_VMT = ^TStream_VMT;

  PStream = ^TStream;

  TStream_Destroy_Proc = Procedure(Const Self: PStream);
  TStream_GetLength_Proc = Function(Const Self: PStream): TSize;
  TStream_GetPosition_Proc = Function(Const Self: PStream): TSize;
  TStream_SetPosition_Proc = Procedure(Const Self: PStream; Value: TSize);
  TStream_Forward_Proc = Function(Const Self: PStream; Offset: TSize): Boolean;
  TStream_Rewind_Proc = Function(Const Self: PStream; Offset: TSize): Boolean;
  TStream_IsEof_Proc = Function(Const Self: PStream): Boolean;
  TStream_Read_Proc = Function(Const Self: PStream; Var Data;
    Const Length: TSize): TSize;
  TStream_Write_Proc = Function(Const Self: PStream; Const Data;
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
    Write: TStream_Write_Proc;
  End;

  TStream = Record
    VMT: PStream_VMT;
  End;

  PFileStream = ^TFileStream;

  TFileStream = Record
    Parent: TStream;
    FFile: File {Of Char};
  End;

  PBinaryFileStream = ^TBinaryFileStream;

  TBinaryFileStream = Record
    Parent: TStream;
    FFile: File {Of Byte};
  End;

Procedure TFileStream_Create(Var Self: PFileStream; Filename: String);
Procedure TFileStream_Destroy(Const Self: PStream);
Function TFileStream_GetLength(Const Self: PStream): TSize;
Function TFileStream_GetPosition(Const Self: PStream): TSize;
Procedure TFileStream_SetPosition(Const Self: PStream; Value: TSize);
Function TFileStream_Forward(Const Self: PStream; Offset: TSize): Boolean;
Function TFileStream_Rewind(Const Self: PStream; Offset: TSize): Boolean;
Function TFileStream_IsEof(Const Self: PStream): Boolean;
Function TFileStream_Read(Const Self: PStream; Var Data; Const Length: TSize): TSize;
Function TFileStream_Write(Const Self: PStream; Const Data; Const Length: TSize): TSize;

Procedure TBinaryFileStream_Create(Var Self: PBinaryFileStream; Filename: String);
Procedure TBinaryFileStream_Destroy(Const Self: PStream);
Function TBinaryFileStream_GetLength(Const Self: PStream): TSize;
Function TBinaryFileStream_GetPosition(Const Self: PStream): TSize;
Procedure TBinaryFileStream_SetPosition(Const Self: PStream; Value: TSize);
Function TBinaryFileStream_Forward(Const Self: PStream; Offset: TSize): Boolean;
Function TBinaryFileStream_Rewind(Const Self: PStream; Offset: TSize): Boolean;
Function TBinaryFileStream_IsEof(Const Self: PStream): Boolean;
Function TBinaryFileStream_Read(Const Self: PStream; Var Data; Const Length: TSize): TSize;
Function TBinaryFileStream_Write(Const Self: PStream; Const Data; Const Length: TSize): TSize;

Implementation

Var
  mTFileStream_VMT: TStream_VMT;
  mTBinaryFileStream_VMT: TStream_VMT;

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
  Result := FileSize(PFileStream(Self)^.FFile)
{$IFDEF UTF16_TEXT} - 1 {$ENDIF}
  ;
End;

Function TFileStream_GetPosition(Const Self: PStream): TSize;
Begin
  Result := FilePos(PFileStream(Self)^.FFile)
{$IFDEF UTF16_TEXT} - 1 {$ENDIF}
  ;
End;

Procedure TFileStream_SetPosition(Const Self: PStream; Value: TSize);
Begin
  Seek(PFileStream(Self)^.FFile, Value
{$IFDEF UTF16_TEXT} + 1 {$ENDIF}
    );
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

Function TFileStream_Read(Const Self: PStream; Var Data; Const Length: TSize): TSize;
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

Function TFileStream_Write(Const Self: PStream; Const Data; Const Length: TSize): TSize;
{$IFDEF WIN64}
Var
  mResult: Integer;
{$ENDIF}
Begin
  {$IFDEF FPC}
  BlockWrite(PFileStream(Self)^.FFile, Data, Int64(Length), Int64(Result));
  {$ELSE}
  {$IFDEF WIN64}
  BlockWrite(PFileStream(Self)^.FFile, Data, Integer(Length), mResult);
  Result := mResult;
  {$ELSE}
  BlockWrite(PFileStream(Self)^.FFile, Data, Length, Result);
  {$ENDIF}
  {$ENDIF}
End;

Procedure TBinaryFileStream_Create(Var Self: PBinaryFileStream; Filename: String);
Begin
  New(Self); { Final }
  Self^.Parent.VMT := @mTBinaryFileStream_VMT;

  AssignFile(Self^.FFile, Filename);
  Rewrite(Self^.FFile, SizeOf(Byte));
End;

Procedure TBinaryFileStream_Destroy(Const Self: PStream);
Begin
  CloseFile(PBinaryFileStream(Self)^.FFile);
End;

Function TBinaryFileStream_GetLength(Const Self: PStream): TSize;
Begin
  Result := FileSize(PBinaryFileStream(Self)^.FFile);
End;

Function TBinaryFileStream_GetPosition(Const Self: PStream): TSize;
Begin
  Result := FilePos(PBinaryFileStream(Self)^.FFile);
End;

Procedure TBinaryFileStream_SetPosition(Const Self: PStream; Value: TSize);
Begin
  Seek(PBinaryFileStream(Self)^.FFile, Value);
End;

Function TBinaryFileStream_Forward(Const Self: PStream; Offset: TSize): Boolean;
Begin
  Seek(PBinaryFileStream(Self)^.FFile, FilePos(PBinaryFileStream(Self)^.FFile) + Offset);
  Result := True;
End;

Function TBinaryFileStream_Rewind(Const Self: PStream; Offset: TSize): Boolean;
Begin
  Seek(PBinaryFileStream(Self)^.FFile, FilePos(PBinaryFileStream(Self)^.FFile) - Offset);
  Result := True;
End;

Function TBinaryFileStream_IsEof(Const Self: PStream): Boolean;
Begin
  Result := EOF(PBinaryFileStream(Self)^.FFile);
End;

Function TBinaryFileStream_Read(Const Self: PStream; Var Data; Const Length: TSize): TSize;
{$IFDEF WIN64}
Var
  mResult: Integer;
{$ENDIF}
Begin
  {$IFDEF FPC}
  BlockRead(PBinaryFileStream(Self)^.FFile, Data, Int64(Length), Int64(Result));
  {$ELSE}
  {$IFDEF WIN64}
  BlockRead(PBinaryFileStream(Self)^.FFile, Data, Integer(Length), mResult);
  Result := mResult;
  {$ELSE}
  BlockRead(PBinaryFileStream(Self)^.FFile, Data, Length, Result);
  {$ENDIF}
  {$ENDIF}
End;

Function TBinaryFileStream_Write(Const Self: PStream; Const Data; Const Length: TSize): TSize;
{$IFDEF WIN64}
Var
  mResult: Integer;
{$ENDIF}
Begin
  {$IFDEF FPC}
  BlockWrite(PBinaryFileStream(Self)^.FFile, Data, Int64(Length), Int64(Result));
  {$ELSE}
  {$IFDEF WIN64}
  BlockWrite(PBinaryFileStream(Self)^.FFile, Data, Integer(Length), mResult);
  Result := mResult;
  {$ELSE}
  BlockWrite(PBinaryFileStream(Self)^.FFile, Data, Length, Result);
  {$ENDIF}
  {$ENDIF}
End;

Begin
  mTFileStream_VMT.Destroy := TFileStream_Destroy;
  mTFileStream_VMT.GetLength := TFileStream_GetLength;
  mTFileStream_VMT.GetPosition := TFileStream_GetPosition;
  mTFileStream_VMT.SetPosition := TFileStream_SetPosition;
  mTFileStream_VMT.Forward := TFileStream_Forward;
  mTFileStream_VMT.Rewind := TFileStream_Rewind;
  mTFileStream_VMT.IsEof := TFileStream_IsEof;
  mTFileStream_VMT.Read := TFileStream_Read;
  mTFileStream_VMT.Write := TFileStream_Write;

  mTBinaryFileStream_VMT.Destroy := TBinaryFileStream_Destroy;
  mTBinaryFileStream_VMT.GetLength := TBinaryFileStream_GetLength;
  mTBinaryFileStream_VMT.GetPosition := TBinaryFileStream_GetPosition;
  mTBinaryFileStream_VMT.SetPosition := TBinaryFileStream_SetPosition;
  mTBinaryFileStream_VMT.Forward := TBinaryFileStream_Forward;
  mTBinaryFileStream_VMT.Rewind := TBinaryFileStream_Rewind;
  mTBinaryFileStream_VMT.IsEof := TBinaryFileStream_IsEof;
  mTBinaryFileStream_VMT.Read := TBinaryFileStream_Read;
  mTBinaryFileStream_VMT.Write := TBinaryFileStream_Write;
End.
