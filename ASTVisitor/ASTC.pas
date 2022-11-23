Unit ASTC;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PAstViewer = ^TAstViewer;

  TAstViewer = Record
    Parent: TAstVisitor;
  End;

Procedure TAstViewer_Create(Self: PAstViewer);
Procedure TAstViewer_Destroy(Self: PAstVisitor);
Procedure TAstViewer_VisitArrayAccess(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitAssign(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitBinaryOp(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitDeref(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitGoto(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitId(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitLabelledStmt(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitLiteral(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitMemberRef(Self: PAstVisitor; Node: PAstNode);
Procedure TAstViewer_VisitUnaryOp(Self: PAstVisitor; Node: PAstNode);

Implementation

Uses
  List, ArrayAccessNode, AssignNode, BinaryOpNode, DerefNode, GotoNode,
  IdNode, LabelledStmtNode, LiteralNode, MemberRefNode, UnaryOpNode;

Procedure TAstViewer_Create(Self: PAstViewer);
Begin
  TAstVisitor_Create(PAstVisitor(Self));
  Self.Parent.VMT.Destory := TAstViewer_Destroy;
  Self.Parent.VMT.VisitArrayAccess := TAstViewer_VisitArrayAccess;
  Self.Parent.VMT.VisitAssign := TAstViewer_VisitAssign;
  Self.Parent.VMT.VisitBinaryOp := TAstViewer_VisitBinaryOp;
  Self.Parent.VMT.VisitDeref := TAstViewer_VisitDeref;
  Self.Parent.VMT.VisitGoto := TAstViewer_VisitGoto;
  Self.Parent.VMT.VisitId := TAstViewer_VisitId;
  Self.Parent.VMT.VisitLabelledStmt := TAstViewer_VisitLabelledStmt;
  Self.Parent.VMT.VisitLiteral := TAstViewer_VisitLiteral;
  Self.Parent.VMT.VisitMemberRef := TAstViewer_VisitMemberRef;
  Self.Parent.VMT.VisitUnaryOp := TAstViewer_VisitUnaryOp;
End;

Procedure TAstViewer_Destroy(Self: PAstVisitor);
Begin
  TAstVisitor_Destroy(Self);
End;

Procedure TAstViewer_VisitArrayAccess(Self: PAstVisitor; Node: PAstNode);
Var
  I: Integer;
  mIndexNode: PAstNode;
  mNode: PArrayAccessNode;
Begin
  mNode := PArrayAccessNode(Node);
  mNode.ArrayExpression.VMT.Accept(mNode.ArrayExpression, Self);
  For I := 0 To mNode.Indices.Size - 1 Do
  Begin
    Write('[');
    mIndexNode := PPAstNode(TList_Get(mNode.Indices, I))^;
    mIndexNode.VMT.Accept(mIndexNode, Self);
    Write(']');
  End;
End;

Procedure TAstViewer_VisitAssign(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PAssignNode;
Begin
  mNode := PAssignNode(Node);
  mNode.LeftHandSide.VMT.Accept(mNode.LeftHandSide, Self);
  Write(' = ');
  mNode.RightHandSide.VMT.Accept(mNode.RightHandSide, Self);
End;

Procedure TAstViewer_VisitBinaryOp(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PBinaryOpNode;
Begin
  mNode := PBinaryOpNode(Node);
  Write('(');
  mNode.LeftNode.VMT.Accept(mNode.LeftNode, Self);
  Case mNode.OpType Of
    eMultiply: Write(' * ');
    eRealDivide: Write(' / ');
    eIntDivide: Write(' / ');
    eModulo: Write(' % ');
    eAnd: Write(' && ');
    eShiftLeft: Write(' << ');
    eShiftRight: Write(' >> ');
    eAs: Write(' AS ');
    eAdd: Write(' + ');
    eSubtract: Write(' - ');
    eOr: Write(' || ');
    eXor: Write(' ^ ');
    eEqual: Write(' = ');
    eNotEqual: Write(' != ');
    eLT: Write(' < ');
    eGT: Write(' > ');
    eLE: Write(' <= ');
    eGE: Write(' >= ');
    eIn: Write(' IN ');
    eIs: Write(' IS ');
  End;
  mNode.RightNode.VMT.Accept(mNode.RightNode, Self);
  Write(')');
End;

Procedure TAstViewer_VisitDeref(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PDerefNode;
Begin
  mNode := PDerefNode(Node);
  Write('*');
  mNode.Expression.VMT.Accept(mNode.Expression, Self);
End;

Procedure TAstViewer_VisitGoto(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PGotoNode;
Begin
  mNode := PGotoNode(Node);
  Write('goto ');
  Write(mNode.LabelName);
End;

Procedure TAstViewer_VisitId(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PIdNode;
Begin
  mNode := PIdNode(Node);
  Write(mNode.Value);
End;

Procedure TAstViewer_VisitLabelledStmt(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PLabelledStmtNode;
Begin
  mNode := PLabelledStmtNode(Node);
  Write(mNode.LabelName);
  Write(': ');
  mNode.Stmt.VMT.Accept(mNode.Stmt, Self);
End;

Procedure TAstViewer_VisitLiteral(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PLiteralNode;
Begin
  mNode := PLiteralNode(Node);
  Write(mNode.Value);
End;

Procedure TAstViewer_VisitMemberRef(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PMemberRefNode;
Begin
  mNode := PMemberRefNode(Node);
  Write('(');
  mNode.Qualifier.VMT.Accept(mNode.Qualifier, Self);
  Write('.');
  Write(mNode.Member);
  Write(')');
End;

Procedure TAstViewer_VisitUnaryOp(Self: PAstVisitor; Node: PAstNode);
Var
  mNode: PUnaryOpNode;
Begin
  mNode := PUnaryOpNode(Node);
  Write('(');
  Case mNode.OpType Of
    eAddress: Write('&');
    eNot: Write('!');
    ePositive: Write('+');
    eNegative: Write('-');
  End;
  mNode.Value.VMT.Accept(mNode.Value, Self);
  Write(')');
End;

End.
