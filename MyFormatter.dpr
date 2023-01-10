Program MyFormatter;
{$APPTYPE CONSOLE}
{$R *.res}
uses
  {$IFNDEF FPC}
  System.SysUtils,
  System.Rtti,
  {$ENDIF }
  ASTNode in 'ASTNode.pas',
  Lexer in 'Lexer.pas',
  Parser in 'Parser.pas',
  Test in 'Test\Test.pas',
  KeywordRule in 'LexerRule\Template\KeywordRule.pas',
  SymbolRule in 'LexerRule\Template\SymbolRule.pas',
  GroupNode in 'AST\GroupNode.pas',
  IdNode in 'AST\IdNode.pas',
  TermNode in 'AST\TermNode.pas',
  GrammarViewer in 'ASTVisitor\GrammarViewer.pas',
  AsteriskRule in 'LexerRule\AsteriskRule.pas',
  ColonRule in 'LexerRule\ColonRule.pas',
  EofRule in 'LexerRule\EofRule.pas',
  IdRule in 'LexerRule\IdRule.pas',
  LParenRule in 'LexerRule\LParenRule.pas',
  OrRule in 'LexerRule\OrRule.pas',
  QuestionMarkRule in 'LexerRule\QuestionMarkRule.pas',
  RParenRule in 'LexerRule\RParenRule.pas',
  SemiRule in 'LexerRule\SemiRule.pas',
  TermRule in 'LexerRule\TermRule.pas',
  ClassUtils in 'Util\ClassUtils.pas',
  List in 'Util\List.pas',
  StringUtils in 'Util\StringUtils.pas',
  Trie in 'Util\Trie.pas',
  TypeDef in 'Util\TypeDef.pas',
  ExprRuleUnit in 'ProductionRule\ExprRuleUnit.pas',
  FactorRuleUnit in 'ProductionRule\FactorRuleUnit.pas',
  GrammarRuleUnit in 'ProductionRule\GrammarRuleUnit.pas',
  GrammarNode in 'AST\GrammarNode.pas',
  RuleNode in 'AST\RuleNode.pas',
  RuleRuleUnit in 'ProductionRule\RuleRuleUnit.pas';

Begin
  ReportMemoryLeaksOnShutdown := True;
  Test1();
End.
