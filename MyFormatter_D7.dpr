Program MyFormatter;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  ASTNode in 'ASTNode.pas',
  Lexer in 'Lexer.pas',
  Parser in 'Parser.pas',
  ExprRuleUnit in 'ProductionRule\ExprRuleUnit.pas',
  FactorRuleUnit in 'ProductionRule\FactorRuleUnit.pas',
  GrammarNode in 'AST\GrammarNode.pas',
  GroupNode in 'AST\GroupNode.pas',
  IdNode in 'AST\IdNode.pas',
  RuleNode in 'AST\RuleNode.pas',
  TermNode in 'AST\TermNode.pas',
  TermRuleNode in 'AST\TermRuleNode.pas',
  GrammarParser in 'ASTVisitor\GrammarParser.pas',
  GrammarViewer in 'ASTVisitor\GrammarViewer.pas',
  NFA in 'Automata\NFA.pas',
  KeywordRule in 'LexerRule\Template\KeywordRule.pas',
  SymbolRule in 'LexerRule\Template\SymbolRule.pas',
  AsteriskRule in 'LexerRule\Grammar\AsteriskRule.pas',
  CharRule in 'LexerRule\Grammar\CharRule.pas',
  ColonRule in 'LexerRule\Grammar\ColonRule.pas',
  DoubleDotsRule in 'LexerRule\Grammar\DoubleDotsRule.pas',
  ParseTree in 'ParseTree\ParseTree.pas',
  GrammarRuleUnit in 'ProductionRule\GrammarRuleUnit.pas',
  RuleRuleUnit in 'ProductionRule\RuleRuleUnit.pas',
  StringFactorRuleUnit in 'ProductionRule\StringFactorRuleUnit.pas',
  TermExprRuleUnit in 'ProductionRule\TermExprRuleUnit.pas',
  TermFactorRuleUnit in 'ProductionRule\TermFactorRuleUnit.pas',
  TermRuleRuleUnit in 'ProductionRule\TermRuleRuleUnit.pas',
  Test1 in 'Test\Test1.pas',
  Test2 in 'Test\Test2.pas',
  Test3 in 'Test\Test3.pas',
  ClassUtils in 'Util\ClassUtils.pas',
  List in 'Util\List.pas',
  TypeDef in 'Util\TypeDef.pas',
  StringUtils in 'Util\StringUtils.pas',
  Trie in 'Util\Trie.pas',
  EofRule in 'LexerRule\Grammar\EofRule.pas',
  IdRule in 'LexerRule\Grammar\IdRule.pas',
  LParenRule in 'LexerRule\Grammar\LParenRule.pas',
  OrRule in 'LexerRule\Grammar\OrRule.pas',
  QuestionMarkRule in 'LexerRule\Grammar\QuestionMarkRule.pas',
  RParenRule in 'LexerRule\Grammar\RParenRule.pas',
  SemiRule in 'LexerRule\Grammar\SemiRule.pas',
  StringRule in 'LexerRule\Grammar\StringRule.pas',
  TermRule in 'LexerRule\Grammar\TermRule.pas';

Begin
  Test3.Test();
End.
