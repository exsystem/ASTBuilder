Unit ASTNode;

{$I define.inc}

Interface

Type
  PPAstNode = ^PAstNode;

  PAstNode = ^TAstNode;

  PAstVisitor = ^IAstVisitor;

  PAstVisitor_Methods = ^TAstVisitor_Methods;

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

  IAstVisitor = Record
    Instance: Pointer;
    Methods: PAstVisitor_Methods;
  End;

  TAstVisitor_Visit_Proc = Procedure(Intf: PAstVisitor; Node: PAstNode);

  TAstVisitor_Methods = Record
    VisitId: TAstVisitor_Visit_Proc;
    VisitTerm: TAstVisitor_Visit_Proc;
    VisitGroup: TAstVisitor_Visit_Proc;
    VisitRule: TAstVisitor_Visit_Proc;
    VisitTermRule: TAstVisitor_Visit_Proc;
    VisitGrammar: TAstVisitor_Visit_Proc;
  End;

Procedure TAstNode_Create(Var Self: PAstNode);
Procedure TAstNode_Destroy(Self: PAstNode);

Implementation

Var
  mTAstNode_VMT: TAstNode_VMT;

Procedure TAstNode_Create(Var Self: PAstNode);
Begin
  { Abstract, no New() call. }
  Self^.VMT := @mTAstNode_VMT;
End;

Procedure TAstNode_Destroy(Self: PAstNode);
Begin
  { NOP }
End;

Begin
  mTAstNode_VMT.Destory := TAstNode_Destroy;
End.
