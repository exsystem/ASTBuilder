Unit ParseTree;

Interface

Uses
  Lexer, List;

Type

  PParseTree = ^TParseTree;

  TParseTree = Record
    RuleName: String;
    Token: TToken;
    Children: PList; // of PParseTree
  End;

Implementation

End.
