Unit ASTNode;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

Interface

Type
  PAstNode = ^TAstNode;

  TAstNode_Destroy_Proc= Procedure(Self: PAstNode);

  PAstNode_VMT = ^TAstNode_VMT;

  TAstNode_VMT = Record
    Destory: TAstNode_Destroy_Proc;
  End;

  TAstNode = Record
    VMT: PAstNode_VMT;
    NodeType: Byte;
  End;

Procedure TAstNode_Create(Self: PAstNode; NodeType: Byte);
Procedure TAstNode_Destroy(Self: PAstNode);

Implementation

Procedure TAstNode_Create(Self: PAstNode; NodeType: Byte);
Begin
  New(Self.VMT);
  Self.VMT.Destory := TAstNode_Destroy;

  Self.NodeType := NodeType;
End;

Procedure TAstNode_Destroy(Self: PAstNode);
Begin
  Dispose(Self.VMT);
End;

End.
