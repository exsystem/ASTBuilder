Unit LabelledStmtNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Const
  CNodeType = Byte($0A);

Type
  PLabelledStmtNode = ^TLabelledStmtNode;

  TLabelledStmtNode = Record
    Parent: TAstNode;
    LabelName: String;
    Stmt: PAstNode;
  End;

Procedure TLabelledStmtNode_Create(Self: PLabelledStmtNode; LabelName: String; Stmt: PAstNode);
Procedure TLabelledStmtNode_Destroy(Self: PAstNode);

Implementation

Procedure TLabelledStmtNode_Create(Self: PLabelledStmtNode; LabelName: String; Stmt: PAstNode);
Begin
  TAstNode_Create(PAstNode(Self), CNodeType);
  Self.Parent.VMT.Destory := TLabelledStmtNode_Destroy;

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

End.
