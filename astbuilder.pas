{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit ASTBuilder;

{$warn 5023 off : no warning about unused units}
interface

uses
  ASTNode, GRMRNODE, GRPNODE, IdNode, RuleNode, TRMNODE, TRMRNODE, NFA, 
  CLEXER, GLEXER, LEXER, ARRWRULE, ASTKRULE, CHARRULE, CHSTRULE, COLNRULE, 
  COMARULE, DDTSRULE, DOTRULE, EOFRULE, EQURULE, IDRULE, LBRKRULE, LCBRULE, 
  LPARRULE, MODERULE, OPTRULE, ORRULE, PLUSRULE, PPMDRULE, PUMDRULE, QMRKRULE, 
  RBRKRULE, RCBRULE, RPARRULE, SEMIRULE, SKIPRULE, STRRULE, TERMRULE, 
  TILDRULE, KYWDRULE, SYMBRULE, CPARSER, GPARSER, GRMRVIWR, PARSER, PARSETR, 
  ACTRUNIT, ASRUNIT, CHFRUNIT, EXPRUNIT, FRUNIT, GRMRUNIT, ICFRUNIT, OPTRUNIT, 
  RRUNIT, SFRUNIT, TERUNIT, TFRUNIT, TRRUNIT, TRSRUNIT, Test1, Test2, TEST3, 
  TestUtil, CLSUTILS, List, STACK, STREAM, StrUtil, Trie, TYPEDEF, Utility, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('ASTBuilder', @Register);
end.
