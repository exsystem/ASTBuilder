Unit ClassUtils;

Interface

Uses
  ASTNode;

Function InstanceOf(Instance: PAstNode; ClassVMT: PAstNode_VMT): Boolean;

Implementation

Function InstanceOf(Instance: PAstNode; ClassVMT: PAstNode_VMT): Boolean;
Begin
  Result := (Instance.VMT = ClassVMT);
End;

End.
