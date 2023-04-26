Program MyFormatter;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  GrmrNode in 'AST\Grmrnode.pas',
  GrpNode in 'AST\Grpnode.pas',
  IdNode in 'AST\IdNode.pas',
  RuleNode in 'AST\RuleNode.pas',
  TrmNode in 'AST\Trmnode.pas',
  TrmRNode in 'AST\Trmrnode.pas',
  GrmrPasr in 'ASTVstr\Grmrpasr.pas',
  GrmrViwr in 'ASTVstr\Grmrviwr.pas',
  NFA in 'Automata\NFA.pas',
  CHSTRULE in 'LexrRule\Grammar\Chstrule.pas',
  CharRule in 'LexrRule\Grammar\Charrule.pas',
  AstkRule in 'LexrRule\Grammar\Astkrule.pas',
  ColnRule in 'LexrRule\Grammar\Colnrule.pas',
  DDtsRule in 'LexrRule\Grammar\Ddtsrule.pas',
  DotRule in 'LexrRule\Grammar\Dotrule.pas',
  EofRule in 'LexrRule\Grammar\Eofrule.pas',
  IdRule in 'LexrRule\Grammar\Idrule.pas',
  LBrkRule in 'LexrRule\Grammar\Lbrkrule.pas',
  LParRule in 'LexrRule\Grammar\Lparrule.pas',
  OrRule in 'LexrRule\Grammar\Orrule.pas',
  PlusRule in 'LexrRule\Grammar\Plusrule.pas',
  QMrkRule in 'LexrRule\Grammar\Qmrkrule.pas',
  RBrkRule in 'LexrRule\Grammar\Rbrkrule.pas',
  RParRule in 'LexrRule\Grammar\Rparrule.pas',
  SemiRule in 'LexrRule\Grammar\Semirule.pas',
  SkipRule in 'LexrRule\Grammar\Skiprule.pas',
  StrRule in 'LexrRule\Grammar\Strrule.pas',
  TermRule in 'LexrRule\Grammar\Termrule.pas',
  TildRule in 'LexrRule\Grammar\Tildrule.pas',
  KywdRule in 'LexrRule\Template\Kywdrule.pas',
  SymbRule in 'LexrRule\Template\Symbrule.pas',
  ParseTr in 'ParseTr\Parsetr.pas',
  ChFRUnit in 'ProdRule\Chfrunit.pas',
  ExpRUnit in 'ProdRule\Exprunit.pas',
  FRUnit in 'ProdRule\Frunit.pas',
  GrmRUnit in 'ProdRule\Grmrunit.pas',
  ICFRUnit in 'ProdRule\Icfrunit.pas',
  RRUnit in 'ProdRule\Rrunit.pas',
  SFRUnit in 'ProdRule\Sfrunit.pas',
  TERUnit in 'ProdRule\Terunit.pas',
  TFRUnit in 'ProdRule\Tfrunit.pas',
  TRRUnit in 'ProdRule\Trrunit.pas',
  Test1 in 'Test\Test1.pas',
  Test2 in 'Test\Test2.pas',
  Test3 in 'Test\Test3.pas',
  TestUtil in 'Test\TestUtil.pas',
  ClsUtils in 'Util\Clsutils.pas',
  List in 'Util\List.pas',
  Stack in 'Util\Stack.pas',
  Trie in 'Util\Trie.pas',
  TypeDef in 'Util\TypeDef.pas',
  ASTNode in 'ASTNode.pas',
  Lexer in 'lexer.pas',
  Parser in 'Parser.pas',
  StrUtil in 'Util\Strutil.pas',
  Utility in 'Util\Utility.pas';

Begin
  Test3.Test();
  ReadLn;
End.
