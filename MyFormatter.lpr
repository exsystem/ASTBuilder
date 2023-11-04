Program MyFormatter;

{$MODE DELPHI}

Uses
  Test1 In 'Test/Test1.pas',
  Test2 In 'Test/Test2.pas',
  Test3 In 'Test/Test3.pas';

// {$R *.res}

Begin
  Test2.Test();
End.
