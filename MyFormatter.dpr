Program MyFormatter;

{$APPTYPE CONSOLE}
{$R *.res}

{.$DEFINE USE_FASTMM5}

uses
  {$IFDEF USE_FASTMM5}
  FastMM5,
  {$ENDIF }
  {$IFNDEF FPC}
  System.SysUtils,
  System.Rtti,
  {$ENDIF }
  NFA in 'Automata\NFA.PAS',
  KYWDRULE in 'LexrRule\Template\KYWDRULE.PAS',
  SYMBRULE in 'LexrRule\Template\SYMBRULE.PAS',
  PARSETR in 'ParseTr\PARSETR.PAS',
  STRUTILS in 'Util\STRUTILS.pas',
  TEST1 in 'Test\TEST1.PAS',
  TEST2 in 'Test\TEST2.PAS',
  TEST3 in 'Test\TEST3.PAS',
  TESTUTIL in 'Test\TESTUTIL.PAS',
  CLEXER in 'LEXER\CLEXER.PAS',
  GLEXER in 'LEXER\GLEXER.PAS',
  LEXER in 'LEXER\LEXER.PAS',
  ASTNode in 'AST\ASTNode.pas',
  GRMRNODE in 'AST\GRMRNODE.PAS',
  GRPNODE in 'AST\GRPNODE.PAS',
  IdNode in 'AST\IdNode.pas',
  RuleNode in 'AST\RuleNode.pas',
  TRMNODE in 'AST\TRMNODE.PAS',
  TRMRNODE in 'AST\TRMRNODE.PAS',
  CLSUTILS in 'Util\CLSUTILS.PAS',
  LIST in 'Util\LIST.PAS',
  STACK in 'Util\STACK.PAS',
  STREAM in 'Util\STREAM.PAS',
  StrUtil in 'Util\StrUtil.pas',
  Trie in 'Util\Trie.pas',
  TypeDef in 'Util\TypeDef.pas',
  Utility in 'Util\Utility.pas',
  ACTRUNIT in 'ProdRule\ACTRUNIT.PAS',
  ASRUNIT in 'ProdRule\ASRUNIT.PAS',
  CHFRUNIT in 'ProdRule\CHFRUNIT.PAS',
  EXPRUNIT in 'ProdRule\EXPRUNIT.PAS',
  FRUNIT in 'ProdRule\FRUNIT.PAS',
  GRMRUNIT in 'ProdRule\GRMRUNIT.PAS',
  ICFRUNIT in 'ProdRule\ICFRUNIT.PAS',
  OPTRUNIT in 'ProdRule\OPTRUNIT.PAS',
  RRUNIT in 'ProdRule\RRUNIT.PAS',
  SFRUNIT in 'ProdRule\SFRUNIT.PAS',
  TERUNIT in 'ProdRule\TERUNIT.PAS',
  TFRUNIT in 'ProdRule\TFRUNIT.PAS',
  TRRUNIT in 'ProdRule\TRRUNIT.PAS',
  TRSRUNIT in 'ProdRule\TRSRUNIT.PAS',
  ARRWRULE in 'LexrRule\Grammar\ARRWRULE.PAS',
  ASTKRULE in 'LexrRule\Grammar\ASTKRULE.PAS',
  CHARRULE in 'LexrRule\Grammar\CHARRULE.PAS',
  CHSTRULE in 'LexrRule\Grammar\CHSTRULE.PAS',
  COLNRULE in 'LexrRule\Grammar\COLNRULE.PAS',
  COMARULE in 'LexrRule\Grammar\COMARULE.PAS',
  DDTSRULE in 'LexrRule\Grammar\DDTSRULE.PAS',
  DOTRULE in 'LexrRule\Grammar\DOTRULE.PAS',
  EOFRULE in 'LexrRule\Grammar\EOFRULE.PAS',
  EQURULE in 'LexrRule\Grammar\EQURULE.PAS',
  IDRULE in 'LexrRule\Grammar\IDRULE.PAS',
  LBRKRULE in 'LexrRule\Grammar\LBRKRULE.PAS',
  LCBRULE in 'LexrRule\Grammar\LCBRULE.PAS',
  LPARRULE in 'LexrRule\Grammar\LPARRULE.PAS',
  MODERULE in 'LexrRule\Grammar\MODERULE.PAS',
  OPTRULE in 'LexrRule\Grammar\OPTRULE.PAS',
  ORRULE in 'LexrRule\Grammar\ORRULE.PAS',
  PLUSRULE in 'LexrRule\Grammar\PLUSRULE.PAS',
  PPMDRULE in 'LexrRule\Grammar\PPMDRULE.PAS',
  PUMDRULE in 'LexrRule\Grammar\PUMDRULE.PAS',
  QMRKRULE in 'LexrRule\Grammar\QMRKRULE.PAS',
  RBRKRULE in 'LexrRule\Grammar\RBRKRULE.PAS',
  RCBRULE in 'LexrRule\Grammar\RCBRULE.PAS',
  RPARRULE in 'LexrRule\Grammar\RPARRULE.PAS',
  SEMIRULE in 'LexrRule\Grammar\SEMIRULE.PAS',
  SKIPRULE in 'LexrRule\Grammar\SKIPRULE.PAS',
  STRRULE in 'LexrRule\Grammar\STRRULE.PAS',
  TERMRULE in 'LexrRule\Grammar\TERMRULE.PAS',
  TILDRULE in 'LexrRule\Grammar\TILDRULE.PAS',
  CPARSER in 'PARSER\CPARSER.PAS',
  GPARSER in 'PARSER\GPARSER.pas',
  GRMRVIWR in 'PARSER\GRMRVIWR.PAS',
  PARSER in 'PARSER\PARSER.pas';

Begin
  {$IFDEF USE_FASTMM5}
  FastMM_LogToFileEvents := [mmetDebugBlockDoubleFree,
    mmetDebugBlockReallocOfFreedBlock, mmetDebugBlockHeaderCorruption,
    mmetDebugBlockFooterCorruption, mmetDebugBlockModifiedAfterFree,
    mmetVirtualMethodCallOnFreedObject,
    mmetAnotherThirdPartyMemoryManagerAlreadyInstalled,
    mmetCannotInstallAfterDefaultMemoryManagerHasBeenUsed,
    mmetCannotSwitchToSharedMemoryManagerWithLivePointers,
    mmetUnexpectedMemoryLeakDetail];

  FastMM_SetEventLogFilename('C:\Users\许子健\Desktop\aaa.log');
  FastMM_LoadDebugSupportLibrary;
  FastMM_EnterDebugMode;
  {$ENDIF}
  ReportMemoryLeaksOnShutdown := True;
  Test3.Test();
  Readln;
End.
