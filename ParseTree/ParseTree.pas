Unit ParseTree;

{$I define.inc}

Interface

Uses
  Lexer, List, TypeDef;

Type
  PPParseTree = ^PParseTree;

  PParseTree = ^TParseTree;

  TParseTree = Record
    RuleName: PChar;
    Token: TToken;
    Children: PList; // of PParseTree
  End;

Procedure TParseTree_Destroy(Self: PParseTree);

Implementation

Procedure TParseTree_Destroy(Self: PParseTree);
Begin
  If Self.Children <> nil Then
  Begin
    While Not TList_IsEmpty(Self.Children) Do
    Begin
      TParseTree_Destroy(PPParseTree(TList_Back(Self.Children))^);
      TList_PopBack(Self.Children);
    End;
    TList_Destroy(Self.Children);
  End;
  Dispose(Self);
End;

End.
