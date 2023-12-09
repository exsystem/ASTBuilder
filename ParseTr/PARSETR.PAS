{ Unit ParseTree; }
Unit ParseTr;

{$I define.inc}

Interface

Uses
  Lexer, List, TypeDef;

Type
  PPParseTree = ^PParseTree;

  PParseTree = ^TParseTree;

  TParseTree = Record
    RuleId: TNonTermRuleId;
    Token: TToken;
    Children: PList; { of PParseTree }
  End;

Procedure TParseTree_Destroy(Self: PParseTree);

Implementation

Uses
 {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil, CLEXER;

Procedure TParseTree_Destroy(Self: PParseTree);
Begin
  FreeStr(Self^.Token.Error);
  FreeStr(Self^.Token.Value);
  Dispose(PTermRule(Self^.Token.Kind));
  If Self^.Children <> nil Then
  Begin
    While Not TList_IsEmpty(Self^.Children) Do
    Begin
      TParseTree_Destroy(PPParseTree(TList_Back(Self^.Children))^);
      TList_PopBack(Self^.Children);
    End;
    TList_Destroy(Self^.Children);
  End;
  Dispose(Self);
End;

End.
