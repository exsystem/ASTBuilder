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
  List in 'Util\List.pas',
  StringUtils in 'Util\StringUtils.pas',
  Trie in 'Util\Trie.pas',
  TypeDef in 'Util\TypeDef.pas',
  ArrayAccessNode in 'AST\ArrayAccessNode.pas',
  AssignNode in 'AST\AssignNode.pas',
  BinaryOpNode in 'AST\BinaryOpNode.pas',
  DerefNode in 'AST\DerefNode.pas',
  GotoNode in 'AST\GotoNode.pas',
  IdNode in 'AST\IdNode.pas',
  LabelledStmtNode in 'AST\LabelledStmtNode.pas',
  LiteralNode in 'AST\LiteralNode.pas',
  MemberRefNode in 'AST\MemberRefNode.pas',
  UnaryOpNode in 'AST\UnaryOpNode.pas',
  EofRule in 'LexerRule\EofRule.pas',
  IdRule in 'LexerRule\IdRule.pas',
  LParenRule in 'LexerRule\LParenRule.pas',
  OrRule in 'LexerRule\OrRule.pas',
  ProduceRule in 'LexerRule\ProduceRule.pas',
  RepeatRule in 'LexerRule\RepeatRule.pas',
  RootRule in 'LexerRule\RootRule.pas',
  RParenRule in 'LexerRule\RParenRule.pas',
  SemiRule in 'LexerRule\SemiRule.pas';

Begin
  ReportMemoryLeaksOnShutdown := True;
  Test1();
End.
