Unit MemberRefNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PMemberRefNode = ^TMemberRefNode;

  TMemberRefNode = Record
    Parent: TAstNode;
    Qualifier: PAstNode;
    Member: String;
  End;

Procedure TMemberRefNode_Create(Self: PMemberRefNode; Qualifier: PAstNode;
  Member: String);
Procedure TMemberRefNode_Destroy(Self: PAstNode);
Procedure TMemberRefNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Implementation

Procedure TMemberRefNode_Create(Self: PMemberRefNode; Qualifier: PAstNode;
  Member: String);
Begin
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT.Destory := TMemberRefNode_Destroy;
  Self.Parent.VMT.Accept := TMemberRefNode_Accept;

  Self.Qualifier := Qualifier;
  Self.Member := Member;
End;

Procedure TMemberRefNode_Destroy(Self: PAstNode);
Begin
  If PMemberRefNode(Self).Qualifier <> nil Then
  Begin
    PMemberRefNode(Self).Qualifier.VMT.Destory(PMemberRefNode(Self).Qualifier);
    Dispose(PMemberRefNode(Self).Qualifier);
  End;
  TAstNode_Destroy(Self);
End;

Procedure TMemberRefNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitMemberRef(Visitor, Self);
End;

End.
