Unit DerefNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PDerefNode = ^TDerefNode;

  TDerefNode = Record
    Parent: TAstNode;
    Expression: PAstNode;
  End;

Procedure TDerefNode_Create(Self: PDerefNode; Expression: PAstNode);
Procedure TDerefNode_Destroy(Self: PAstNode);
Procedure TDerefNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Implementation

Procedure TDerefNode_Create(Self: PDerefNode; Expression: PAstNode);
Begin
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT.Destory := TDerefNode_Destroy;
  Self.Parent.VMT.Accept := TDerefNode_Accept;

  Self.Expression := Expression;
End;

Procedure TDerefNode_Destroy(Self: PAstNode);
Begin
  If PDerefNode(Self).Expression <> nil Then
  Begin
    PDerefNode(Self).Expression.VMT.Destory(PDerefNode(Self).Expression);
    Dispose(PDerefNode(Self).Expression);
  End;
  TAstNode_Destroy(Self);
End;

Procedure TDerefNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitDeref(Visitor, Self);
End;

End.
