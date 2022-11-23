Unit LabelledStmtNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PLabelledStmtNode = ^TLabelledStmtNode;

  TLabelledStmtNode = Record
    Parent: TAstNode;
    LabelName: String;
    Stmt: PAstNode;
  End;

Procedure TLabelledStmtNode_Create(Self: PLabelledStmtNode; LabelName: String;
  Stmt: PAstNode);
Procedure TLabelledStmtNode_Destroy(Self: PAstNode);
Procedure TLabelledStmtNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Implementation

Procedure TLabelledStmtNode_Create(Self: PLabelledStmtNode; LabelName: String;
  Stmt: PAstNode);
Begin
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT.Destory := TLabelledStmtNode_Destroy;
  Self.Parent.VMT.Accept := TLabelledStmtNode_Accept;

  Self.LabelName := LabelName;
  Self.Stmt := Stmt;
End;

Procedure TLabelledStmtNode_Destroy(Self: PAstNode);
Begin
  If PLabelledStmtNode(Self).Stmt <> nil Then
  Begin
    PLabelledStmtNode(Self).Stmt.VMT.Destory(PLabelledStmtNode(Self).Stmt);
    Dispose(PLabelledStmtNode(Self).Stmt);
  End;
  TAstNode_Destroy(Self);
End;

Procedure TLabelledStmtNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitLabelledStmt(Visitor, Self);
End;

End.
