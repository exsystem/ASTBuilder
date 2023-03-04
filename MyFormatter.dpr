Program MyFormatter;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  FastMM5,
  {$IFNDEF FPC}
  System.SysUtils,
  System.Rtti,
  {$ENDIF }
  ASTNode in 'ASTNode.pas',
  Lexer in 'Lexer.pas',
  Parser in 'Parser.pas',
  KeywordRule in 'LexerRule\Template\KeywordRule.pas',
  SymbolRule in 'LexerRule\Template\SymbolRule.pas',
  GrammarViewer in 'ASTVisitor\GrammarViewer.pas',
  ClassUtils in 'Util\ClassUtils.pas',
  List in 'Util\List.pas',
  StringUtils in 'Util\StringUtils.pas',
  Trie in 'Util\Trie.pas',
  TypeDef in 'Util\TypeDef.pas',
  Test2 in 'Test\Test2.pas',
  GrammarParser in 'ASTVisitor\GrammarParser.pas',
  ParseTree in 'ParseTree\ParseTree.pas',
  GrammarNode in 'AST\GrammarNode.pas',
  GroupNode in 'AST\GroupNode.pas',
  IdNode in 'AST\IdNode.pas',
  RuleNode in 'AST\RuleNode.pas',
  TermNode in 'AST\TermNode.pas',
  Test1 in 'Test\Test1.pas',
  TermRuleNode in 'AST\TermRuleNode.pas',
  NFA in 'Automata\NFA.pas',
  Test3 in 'Test\Test3.pas',
  AsteriskRule in 'LexerRule\Grammar\AsteriskRule.pas',
  CharRule in 'LexerRule\Grammar\CharRule.pas',
  ColonRule in 'LexerRule\Grammar\ColonRule.pas',
  DoubleDotsRule in 'LexerRule\Grammar\DoubleDotsRule.pas',
  EofRule in 'LexerRule\Grammar\EofRule.pas',
  IdRule in 'LexerRule\Grammar\IdRule.pas',
  LBracketRule in 'LexerRule\Grammar\LBracketRule.pas',
  LParenRule in 'LexerRule\Grammar\LParenRule.pas',
  OrRule in 'LexerRule\Grammar\OrRule.pas',
  PlusRule in 'LexerRule\Grammar\PlusRule.pas',
  QuestionMarkRule in 'LexerRule\Grammar\QuestionMarkRule.pas',
  RBracketRule in 'LexerRule\Grammar\RBracketRule.pas',
  RParenRule in 'LexerRule\Grammar\RParenRule.pas',
  SemiRule in 'LexerRule\Grammar\SemiRule.pas',
  SkipRule in 'LexerRule\Grammar\SkipRule.pas',
  StringRule in 'LexerRule\Grammar\StringRule.pas',
  TermRule in 'LexerRule\Grammar\TermRule.pas',
  TildeRule in 'LexerRule\Grammar\TildeRule.pas',
  CharFactorRuleUnit in 'ProductionRule\CharFactorRuleUnit.pas',
  ExprRuleUnit in 'ProductionRule\ExprRuleUnit.pas',
  FactorRuleUnit in 'ProductionRule\FactorRuleUnit.pas',
  GrammarRuleUnit in 'ProductionRule\GrammarRuleUnit.pas',
  IndividualCharFactorRuleUnit in 'ProductionRule\IndividualCharFactorRuleUnit.pas',
  RuleRuleUnit in 'ProductionRule\RuleRuleUnit.pas',
  StringFactorRuleUnit in 'ProductionRule\StringFactorRuleUnit.pas',
  TermExprRuleUnit in 'ProductionRule\TermExprRuleUnit.pas',
  TermFactorRuleUnit in 'ProductionRule\TermFactorRuleUnit.pas',
  TermRuleRuleUnit in 'ProductionRule\TermRuleRuleUnit.pas',
  TestUtil in 'Test\TestUtil.pas';

Begin
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

  ReportMemoryLeaksOnShutdown := True;
  Test3.Test();
End.
