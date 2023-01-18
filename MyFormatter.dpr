Program MyFormatter;

{$APPTYPE CONSOLE}
{$R *.res}
Uses {$IFNDEF FPC}
  System.SysUtils,
  System.Rtti, {$ENDIF }
  ASTNode In 'ASTNode.pas',
  Lexer In 'Lexer.pas',
  Parser In 'Parser.pas',
  KeywordRule In 'LexerRule\Template\KeywordRule.pas',
  SymbolRule In 'LexerRule\Template\SymbolRule.pas',
  GroupNode In 'AST\GroupNode.pas',
  IdNode In 'AST\IdNode.pas',
  TermNode In 'AST\TermNode.pas',
  GrammarViewer In 'ASTVisitor\GrammarViewer.pas',
  ClassUtils In 'Util\ClassUtils.pas',
  List In 'Util\List.pas',
  StringUtils In 'Util\StringUtils.pas',
  Trie In 'Util\Trie.pas',
  TypeDef In 'Util\TypeDef.pas',
  ExprRuleUnit In 'ProductionRule\ExprRuleUnit.pas',
  FactorRuleUnit In 'ProductionRule\FactorRuleUnit.pas',
  GrammarRuleUnit In 'ProductionRule\GrammarRuleUnit.pas',
  GrammarNode In 'AST\GrammarNode.pas',
  RuleNode In 'AST\RuleNode.pas',
  RuleRuleUnit In 'ProductionRule\RuleRuleUnit.pas',
  Test2 In 'Test\Test2.pas',
  GrammarParser In 'ASTVisitor\GrammarParser.pas',
  ParseTree In 'ParseTree\ParseTree.pas',
  AsteriskRule In 'LexerRule\Grammar\AsteriskRule.pas',
  ColonRule In 'LexerRule\Grammar\ColonRule.pas',
  EofRule In 'LexerRule\Grammar\EofRule.pas',
  IdRule In 'LexerRule\Grammar\IdRule.pas',
  LParenRule In 'LexerRule\Grammar\LParenRule.pas',
  OrRule In 'LexerRule\Grammar\OrRule.pas',
  QuestionMarkRule In 'LexerRule\Grammar\QuestionMarkRule.pas',
  RParenRule In 'LexerRule\Grammar\RParenRule.pas',
  SemiRule In 'LexerRule\Grammar\SemiRule.pas',
  TermRule In 'LexerRule\Grammar\TermRule.pas';

Begin
  ReportMemoryLeaksOnShutdown := True;
  Test();
End.
