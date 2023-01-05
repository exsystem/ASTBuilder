Unit ASTNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Type
  PPAstNode = ^PAstNode;

  PAstNode = ^TAstNode;

  PAstVisitor = ^TAstVisitor;

  TAstNode_Destroy_Proc = Procedure(Self: PAstNode);

  TAstNode_Accept_Proc = Procedure(Self: PAstNode; Visitor: PAstVisitor);

  PAstNode_VMT = ^TAstNode_VMT;

  TAstNode_VMT = Record
    Destory: TAstNode_Destroy_Proc;
    Accept: TAstNode_Accept_Proc;
  End;

  TAstNode = Record
    VMT: PAstNode_VMT;
  End;

  PAstVisitor_VMT = ^TAstVisitor_VMT;

  TAstVisitor_Destroy_Proc = Procedure(Self: PAstVisitor);

  TAstVisitor_Visit_Proc = Procedure(Self: PAstVisitor; Node: PAstNode);

  TAstVisitor_VMT = Record
    Destory: TAstVisitor_Destroy_Proc;
    VisitArrayAccess: TAstVisitor_Visit_Proc;
    VisitAssign: TAstVisitor_Visit_Proc;
    VisitBinaryOp: TAstVisitor_Visit_Proc;
    VisitDeref: TAstVisitor_Visit_Proc;
    VisitGoto: TAstVisitor_Visit_Proc;
    VisitId: TAstVisitor_Visit_Proc;
    VisitLabelledStmt: TAstVisitor_Visit_Proc;
    VisitLiteral: TAstVisitor_Visit_Proc;
    VisitMemberRef: TAstVisitor_Visit_Proc;
    VisitUnaryOp: TAstVisitor_Visit_Proc;
  End;

  TAstVisitor = Record
    VMT: PAstVisitor_VMT;
  End;

Procedure TAstNode_Create(Self: PAstNode);
Procedure TAstNode_Destroy(Self: PAstNode);

Procedure TAstVisitor_Create(Self: PAstVisitor);
Procedure TAstVisitor_Destroy(Self: PAstVisitor);

Implementation

Procedure TAstNode_Create(Self: PAstNode);
Begin
  New(Self.VMT);
  Self.VMT.Destory := TAstNode_Destroy;
End;

Procedure TAstNode_Destroy(Self: PAstNode);
Begin
  Dispose(Self.VMT);
End;

Procedure TAstVisitor_Create(Self: PAstVisitor);
Begin
  New(Self.VMT);
  Self.VMT.Destory := TAstVisitor_Destroy;
End;

Procedure TAstVisitor_Destroy(Self: PAstVisitor);
Begin
  Dispose(Self.VMT);
End;

End.

