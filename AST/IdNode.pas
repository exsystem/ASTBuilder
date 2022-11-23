Unit IdNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PIdNode = ^TIdNode;

  TIdNode = Record
    Parent: TAstNode;
    Value: String;
    _Test: Integer;
  End;

Procedure TIdNode_Create(Self: PIdNode; Value: String);

Procedure TIdNode_Destroy(Self: PAstNode);

Procedure TIdNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Implementation

Procedure TIdNode_Create(Self: PIdNode; Value: String);
Begin
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT.Destory := TIdNode_Destroy;
  Self.Parent.VMT.Accept := TIdNode_Accept;

  Self.Value := Value;
  Self._Test := $55AA;
End;

Procedure TIdNode_Destroy(Self: PAstNode);
Begin
  TAstNode_Destroy(Self);
End;

Procedure TIdNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitId(Visitor, Self);
End;

End.

