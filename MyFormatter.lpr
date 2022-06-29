Program MyFormatter;

{$MODE DELPHI}

Uses
  SysUtils,
  Lexer,
  AddRule,
  DivRule,
  EofRule,
  LParentRule,
  MulRule,
  NumRule,
  RParentRule,
  SubRule;

Var
  mSource: String;
  mLexer: PLexer;
  mToken: TToken;
Begin
  mSource := '6 + 7*  ABC )(*+/)2 ! 4784378@ - 738) *(877(9';
  //mSource := '8@';
  mLexer := TLexer_Create(mSource);
  TLexer_AddRule(mLexer, EofRule.Compose());
  TLexer_AddRule(mLexer, AddRule.Compose());
  TLexer_AddRule(mLexer, SubRule.Compose());
  TLexer_AddRule(mLexer, MulRule.Compose());
  TLexer_AddRule(mLexer, DivRule.Compose());
  TLexer_AddRule(mLexer, LParentRule.Compose());
  TLexer_AddRule(mLexer, RParentRule.Compose());
  TLexer_AddRule(mLexer, NumRule.Compose());
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
