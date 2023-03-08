{ Unit TermNode; }
Unit TrmNode;

{$I define.inc}

Interface

Uses
  ASTNode, lexer;

Type
  PTermNode = ^TTermNode;

  TTermNode = Record
    Parent: TAstNode;
    Token: TToken;
  End;

Procedure TTermNode_Create(Var Self: PTermNode);

Procedure TTermNode_Destroy(Self: PAstNode);

Procedure TTermNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTTermNode_AST: TAstNode_VMT;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtils;

Procedure TTermNode_Create(Var Self: PTermNode);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self^.Parent.VMT := @mTTermNode_AST;
  Self^.Token.Error := strnew('');
  Self^.Token.Value := strnew('');
  Self^.Token.Kind.TermRule := strnew('');
End;

Procedure TTermNode_Destroy(Self: PAstNode);
Begin
  FreeStr(PTermNode(Self)^.Token.Error);
  FreeStr(PTermNode(Self)^.Token.Value);
  FreeStr(PTermNode(Self)^.Token.Kind.TermRule);
  TAstNode_Destroy(Self);
End;

Procedure TTermNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor^.VMT^.VisitTerm(Visitor, Self);
End;

Begin
  mTTermNode_AST.Destory := TTermNode_Destroy;
  mTTermNode_AST.Accept := TTermNode_Accept;
End.
