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
  List in 'List.pas',
  Parser in 'Parser.pas',
  StringUtils in 'StringUtils.pas',
  TypeDef in 'TypeDef.pas',
  BinaryOpNode in 'AST\BinaryOpNode.pas',
  LiteralNode in 'AST\LiteralNode.pas',
  Test in 'Test\Test.pas',
  KeywordRule in 'LexerRule\Template\KeywordRule.pas',
  SymbolRule in 'LexerRule\Template\SymbolRule.pas',
  UnaryOpNode in 'AST\UnaryOpNode.pas',
  AndRule in 'LexerRule\AndRule.pas',
  AsRule in 'LexerRule\AsRule.pas',
  DivRule in 'LexerRule\DivRule.pas',
  EofRule in 'LexerRule\EofRule.pas',
  EqualRule in 'LexerRule\EqualRule.pas',
  GERule in 'LexerRule\GERule.pas',
  GTRule in 'LexerRule\GTRule.pas',
  InRule in 'LexerRule\InRule.pas',
  IsRule in 'LexerRule\IsRule.pas',
  LERule in 'LexerRule\LERule.pas',
  LParentRule in 'LexerRule\LParentRule.pas',
  LTRule in 'LexerRule\LTRule.pas',
  MinusRule in 'LexerRule\MinusRule.pas',
  ModRule in 'LexerRule\ModRule.pas',
  MulRule in 'LexerRule\MulRule.pas',
  NotEqualRule in 'LexerRule\NotEqualRule.pas',
  NotRule in 'LexerRule\NotRule.pas',
  NumRule in 'LexerRule\NumRule.pas',
  OrRule in 'LexerRule\OrRule.pas',
  PlusRule in 'LexerRule\PlusRule.pas',
  RParentRule in 'LexerRule\RParentRule.pas',
  ShlRule in 'LexerRule\ShlRule.pas',
  ShrRule in 'LexerRule\ShrRule.pas',
  SlashRule in 'LexerRule\SlashRule.pas',
  XorRule in 'LexerRule\XorRule.pas',
  AddFactorRuleUnit in 'ProductionRule\AddFactorRuleUnit.pas',
  AddOpRuleUnit in 'ProductionRule\AddOpRuleUnit.pas',
  ExprRuleUnit in 'ProductionRule\ExprRuleUnit.pas',
  MulOpRuleUnit in 'ProductionRule\MulOpRuleUnit.pas',
  RelFactorRuleUnit in 'ProductionRule\RelFactorRuleUnit.pas',
  RelOpRuleUnit in 'ProductionRule\RelOpRuleUnit.pas',
  TermRuleUnit in 'ProductionRule\TermRuleUnit.pas';

Begin
  Test1();
End.
