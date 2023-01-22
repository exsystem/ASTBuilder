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
    VisitId: TAstVisitor_Visit_Proc;
    VisitTerm: TAstVisitor_Visit_Proc;
    VisitGroup: TAstVisitor_Visit_Proc;
    VisitRule: TAstVisitor_Visit_Proc;
    VisitGrammar: TAstVisitor_Visit_Proc;
    VisitString: TAstVisitor_Visit_Proc;
    VisitRange: TAstVisitor_Visit_Proc;
  End;

  TAstVisitor = Record
    VMT: PAstVisitor_VMT;
  End;

Procedure TAstNode_Create(Var Self: PAstNode);
Procedure TAstNode_Destroy(Self: PAstNode);

Procedure TAstVisitor_Create(Var Self: PAstVisitor);
Procedure TAstVisitor_Destroy(Self: PAstVisitor);

Implementation

Var
  mTAstNode_VMT: TAstNode_VMT;
  mTAstVisitor_VMT: TAstVisitor_VMT;

Procedure TAstNode_Create(Var Self: PAstNode);
Begin
  // Abstract, no New() call.
  Self.VMT := @mTAstNode_VMT;
End;

Procedure TAstNode_Destroy(Self: PAstNode);
Begin
  // NOP
End;

Procedure TAstVisitor_Create(Var Self: PAstVisitor);
Begin
  Self.VMT := @mTAstVisitor_VMT;
End;

Procedure TAstVisitor_Destroy(Self: PAstVisitor);
Begin
  // NOP
End;

Begin
  mTAstNode_VMT.Destory := TAstNode_Destroy;
  mTAstVisitor_VMT.Destory := TAstVisitor_Destroy;
End.
