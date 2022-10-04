Program MyFormatter;

{$MODE DELPHI}

Uses
  SysUtils,
  Lexer,
  Parser,
  AddRule,
  DivRule,
  EofRule,
  LParentRule,
  MulRule,
  NumRule,
  RParentRule,
  SubRule,
  ExprRule;

Var
  mSource: String;
  mLexer: PLexer;
  mParser: PParser;
Begin
  //mSource := '6 + 7*  ABC )(*+/)2 ! 4784378@ - 738) *(877(9';
  //mSource := '8+/2';
  //mSource := '2*9+(21-1*7)/2';
  //mSource := '3';
  //mSource := '8@';
  While True Do
  Begin
    ReadLn(mSource);
    If mSource = '' Then
    Begin
      Exit;
    End;
    mLexer := TLexer_Create(mSource);
    TLexer_AddRule(mLexer, EofRule.Compose());
    TLexer_AddRule(mLexer, AddRule.Compose());
    TLexer_AddRule(mLexer, SubRule.Compose());
    TLexer_AddRule(mLexer, MulRule.Compose());
    TLexer_AddRule(mLexer, DivRule.Compose());
    TLexer_AddRule(mLexer, LParentRule.Compose());
    TLexer_AddRule(mLexer, RParentRule.Compose());
    TLexer_AddRule(mLexer, NumRule.Compose());
    mParser := TParser_Create(mLexer, ExprRule.ExprRule);
    If TParser_Parse(mParser) Then
      WriteLn('ACCEPTED')
    Else
      WriteLn('ERROR');
    TParser_Destroy(mParser);
    TLexer_Destroy(mLexer);
  End;
End.
