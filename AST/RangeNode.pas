Unit RangeNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Uses
  ASTNode;

Type
  PRangeNode = ^TRangeNode;

  TRangeNode = Record
    Parent: TAstNode;
    FromChar: Char;
    ToChar: Char;
  End;

Procedure TRangeNode_Create(Var Self: PRangeNode; FromChar: Char; ToChar: Char);

Procedure TRangeNode_Destroy(Self: PAstNode);

Procedure TRangeNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Var
  mTRangeNode_AST: TAstNode_VMT;

Implementation

Procedure TRangeNode_Create(Var Self: PRangeNode; FromChar: Char; ToChar: Char);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self.Parent.VMT := @mTRangeNode_AST;

  Self.FromChar := FromChar;
  Self.ToChar := ToChar;
End;

Procedure TRangeNode_Destroy(Self: PAstNode);
Begin
  TAstNode_Destroy(Self);
End;

Procedure TRangeNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor.VMT.VisitRange(Visitor, Self);
End;

Begin
  mTRangeNode_AST.Destory := TRangeNode_Destroy;
  mTRangeNode_AST.Accept := TRangeNode_Accept;
End.
