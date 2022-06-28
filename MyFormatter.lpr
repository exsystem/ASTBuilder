Program MyFormatter;

{$MODE DELPHI}

Uses
  SysUtils,
  Lexer;

Var
  mSource: String;
  mLexer: PLexer;
  mToken: TToken;
Begin
  mSource := '6 + 7*  ABC )(*+/)2 ! 4784378@ - 738) *(877(9';
  //mSource := '8@';
  mLexer := TLexer_Create(mSource);
  WriteLn('**********');
  WriteLn(mSource);
  WriteLn('**********');
  Repeat
    If TLexer_GetNextToken(mLexer, mToken) Then
    Begin
      WriteLn(Format('token kind = %d: %s @ pos = %d',
        [mToken.Kind, mToken.Value, mToken.StartPos]));
      Continue;
    End;
    WriteLn(Format('[ERROR] Illegal token "%s" found at pos %d.',
      [mToken.Value, mToken.StartPos]));
  Until mLexer.CurrentChar = #0;
  TLexer_Destroy(mLexer);
End.
