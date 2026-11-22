{ Test program for StreamReader }

Program TestStreamReader;

{$MODE DELPHI}
{$APPTYPE CONSOLE}
{$H+}{ Enable long strings (AnsiString) }

Uses
  SysUtils,
  TypeDef In '..\Util\TypeDef.pas',
  Stream In '..\Util\Stream.pas',
  StreamReader In '..\Util\StreamReader.pas';

Var
  mReader: PStreamReader;
  mChBytes: Array[0..3] Of Byte;
  mBytesRead: QWord;
  mLine: String;
  mText: String;
  mInfo: TEncodingInfo;
  I: Integer;
  mChString: String;
  mGlobalReadTest: Boolean;

Begin
  WriteLn('=== StreamReader Test ===');
  WriteLn;

  TChar_SetGlobalEncoding(ekGBK);
  TStreamReader_Create(mReader, 'TestCase/test_chinese_utf8.txt');
  If mReader^.Parent.Encoding <> ekGBK Then
    Halt(10);
  TStreamReader_Destroy(PStream(mReader));

  mGlobalReadTest := False;
  mReader := nil;
  Try
    TStreamReader_Create(mReader, 'TestCase/test_chinese_utf8.txt', ekUTF8);
  Except
    On E: EConvertError Do
      mGlobalReadTest := True;
  End;
  If Not mGlobalReadTest Then
  Begin
    TStreamReader_Destroy(PStream(mReader));
    Halt(11);
  End;
  TChar_SetGlobalEncoding(ekUTF8);

  { Test 1: Read Chinese UTF-8 file }
  WriteLn('Test 1: Reading Chinese UTF-8 file');
  WriteLn('-----------------------------------');

  TStreamReader_Create(mReader, 'TestCase/test_chinese_utf8.txt');

  { Read all text }
  If TStreamReader_ReadAllText(mReader, mText) > 0 Then
  Begin
    WriteLn('Content Length: ', Length(mText));
    WriteLn('Content: [' + mText + ']');
  End
  Else
    WriteLn('ReadAllText failed or returned empty');

  TStreamReader_Destroy(PStream(mReader));

  { Test 2: Read character by character using raw bytes }
  WriteLn;
  WriteLn('Test 2: Reading character by character (raw bytes)');
  WriteLn('----------------------------------------------------');

  TStreamReader_Create(mReader, 'TestCase/test_chinese_utf8.txt');

  Write('First 15 characters: ');
  For I := 1 To 15 Do
  Begin
    //mBytesRead := TStreamReader_ReadChar(mReader, @mChBytes[0], SizeOf(mChBytes));
    TStreamReader_Read(PStream(mReader), mChBytes[0], 1, mBytesRead);
    If mBytesRead <= 0 Then
      Break;

    { Display byte values }
    SetLength(mLine, mBytesRead);
    Move(mChBytes[0], mLine[1], mBytesRead);
    Write('[', mLine, ']');
  End;
  WriteLn;

  TStreamReader_Destroy(PStream(mReader));

  { Test 3: Read line by line }
  WriteLn;
  WriteLn('Test 3: Reading line by line');
  WriteLn('------------------------------');

  TStreamReader_Create(mReader, 'TestCase/test_chinese_utf8.txt');

  WriteLn('Lines:');
  While TStreamReader_ReadLine(mReader, mLine) Do
  Begin
    WriteLn('  Line: [', mLine, ']');
  End;

  TStreamReader_Destroy(PStream(mReader));

  { Test 4: Detect encoding }
  WriteLn;
  WriteLn('Test 4: Auto-detect encoding');
  WriteLn('------------------------------');

  If TStreamReader_DetectEncoding('TestCase/test_chinese_utf8.txt', mInfo) Then
  Begin
    WriteLn('Detected encoding: ', TStreamReader_GetEncodingName(mInfo.Kind));
    WriteLn('BOM size: ', mInfo.BOMSize);
  End;

  { Test 5: Read character as string (all characters) }
  WriteLn;
  WriteLn('Test 5: Reading character by character (as strings)');
  WriteLn('------------------------------------------------------');

  TStreamReader_Create(mReader, 'TestCase/test_chinese_utf8.txt');

  Write('All characters as strings: ');
  While TStreamReader_ReadCharToString(mReader, mChString) Do
    Write('[', mChString, ']');
  WriteLn;

  TStreamReader_Destroy(PStream(mReader));

  WriteLn;
  WriteLn('=== All tests completed ===');
  ReadLn;
End.
