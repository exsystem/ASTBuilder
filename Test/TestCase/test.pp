PROGRAM TEST;

VAR
  FOO: BYTE;
  BAR: STRING;
BEGIN
  {hello}
  IF (FOO > 12.345) OR (BAR = 'test') THEN
  BEGIN
    FOR I := 100 DOWNTO -100 DO
    BEGIN
      P := FUNC1(I);
    END;
    READLN;
    WRITELN('hello {this is not comment at all {{{}}}}' + ' byebye');
  END;
  EXIT;
  {byebye}
END.
