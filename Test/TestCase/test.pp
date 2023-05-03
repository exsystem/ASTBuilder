Program TEST;

Var
  mFoo: Byte;
  mBar: String;
Begin
  {hello}
  If (mFoo > 12.345) Or (mBar = 'test') Then
  Begin
    For I := 100 Downto -100 Do
    Begin
      P := Func1(I);
    End;
    ReAdLn;
    WriteLn('hello {this is not comment at all {{{}}}}' + ' byebye');
  End;
  ExIt;
  {byebye}
End.
