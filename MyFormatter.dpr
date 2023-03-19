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
  ASTNode in 'ASTNode.pas',
  Lexer in 'Lexer.pas',
  Parser in 'Parser.pas',
  GRMRNODE in 'AST\GRMRNODE.PAS',
  GRPNODE in 'AST\GRPNODE.PAS',
  IDNODE in 'AST\IDNODE.PAS',
  RULENODE in 'AST\RULENODE.PAS',
  TRMNODE in 'AST\TRMNODE.PAS',
  TRMRNODE in 'AST\TRMRNODE.PAS',
  GRMRPASR in 'ASTVstr\GRMRPASR.PAS',
  GRMRVIWR in 'ASTVstr\GRMRVIWR.PAS',
  NFA in 'Automata\NFA.PAS',
  ASTKRULE in 'LexrRule\Grammar\ASTKRULE.PAS',
  CHARRULE in 'LexrRule\Grammar\CHARRULE.PAS',
  COLNRULE in 'LexrRule\Grammar\COLNRULE.PAS',
  DDTSRULE in 'LexrRule\Grammar\DDTSRULE.PAS',
  EOFRULE in 'LexrRule\Grammar\EOFRULE.PAS',
  IDRULE in 'LexrRule\Grammar\IDRULE.PAS',
  LBRKRULE in 'LexrRule\Grammar\LBRKRULE.PAS',
  LPARRULE in 'LexrRule\Grammar\LPARRULE.PAS',
  ORRULE in 'LexrRule\Grammar\ORRULE.PAS',
  PLUSRULE in 'LexrRule\Grammar\PLUSRULE.PAS',
  QMRKRULE in 'LexrRule\Grammar\QMRKRULE.PAS',
  RBRKRULE in 'LexrRule\Grammar\RBRKRULE.PAS',
  RPARRULE in 'LexrRule\Grammar\RPARRULE.PAS',
  SEMIRULE in 'LexrRule\Grammar\SEMIRULE.PAS',
  SKIPRULE in 'LexrRule\Grammar\SKIPRULE.PAS',
  STRRULE in 'LexrRule\Grammar\STRRULE.PAS',
  TERMRULE in 'LexrRule\Grammar\TERMRULE.PAS',
  TILDRULE in 'LexrRule\Grammar\TILDRULE.PAS',
  KYWDRULE in 'LexrRule\Template\KYWDRULE.PAS',
  SYMBRULE in 'LexrRule\Template\SYMBRULE.PAS',
  PARSETR in 'ParseTr\PARSETR.PAS',
  CHFRUNIT in 'ProdRule\CHFRUNIT.PAS',
  EXPRUNIT in 'ProdRule\EXPRUNIT.PAS',
  FRUNIT in 'ProdRule\FRUNIT.PAS',
  GRMRUNIT in 'ProdRule\GRMRUNIT.PAS',
  ICFRUNIT in 'ProdRule\ICFRUNIT.PAS',
  RRUNIT in 'ProdRule\RRUNIT.PAS',
  SFRUNIT in 'ProdRule\SFRUNIT.PAS',
  TERUNIT in 'ProdRule\TERUNIT.PAS',
  TFRUNIT in 'ProdRule\TFRUNIT.PAS',
  TRRUNIT in 'ProdRule\TRRUNIT.PAS',
  CLSUTILS in 'Util\CLSUTILS.PAS',
  LIST in 'Util\LIST.PAS',
  STRUTILS in 'Util\STRUTILS.PAS',
  TRIE in 'Util\TRIE.PAS',
  TYPEDEF in 'Util\TYPEDEF.PAS',
  TEST1 in 'Test\TEST1.PAS',
  TEST2 in 'Test\TEST2.PAS',
  TEST3 in 'Test\TEST3.PAS',
  TESTUTIL in 'Test\TESTUTIL.PAS',
  CHSTRULE in 'LexrRule\Grammar\CHSTRULE.PAS',
  DOTRULE in 'LexrRule\Grammar\DOTRULE.PAS';

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
