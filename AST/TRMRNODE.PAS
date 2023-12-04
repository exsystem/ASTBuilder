{ Unit TermRuleNode; }
Unit TrmRNode;

{$I define.inc}

Interface

Uses
  ASTNode, NFA, LIST, TypeDef;

Type

  TCommandType = (eSkipCommand, ePushModeCommand, ePopModeCommand);

  PCommand = ^TCommand;

  TCommand = Record
    CommandType: TCommandType;
    Arg: PChar;
  End;

  PPTermRuleNode = ^PTermRuleNode;
  PTermRuleNode = ^TTermRuleNode;

  TTermRuleNode = Record
    Parent: TAstNode;
    TermRuleId: TTermRule;
    Nfa: PNfa;
    CommandList: PList; { <TCommand> }
  End;

Procedure TTermRuleNode_Create(Var Self: PTermRuleNode);

Procedure TTermRuleNode_Destroy(Self: PAstNode);

Procedure TTermRuleNode_Accept(Self: PAstNode; Visitor: PAstVisitor);

Procedure TTermRuleNode_AddSkipCommand(Self: PTermRuleNode);

Procedure TTermRuleNode_AddPushModeCommand(Self: PTermRuleNode; Mode: PChar);

Procedure TTermRuleNode_AddPopModeCommand(Self: PTermRuleNode);
Var
  mTTermRuleNode_AST: TAstNode_VMT;

Implementation

Uses
  {$IFDEF USE_STRINGS}strings{$ELSE}SysUtils{$ENDIF}, StrUtil;

Procedure TTermRuleNode_Create(Var Self: PTermRuleNode);
Begin
  New(Self);
  TAstNode_Create(PAstNode(Self));
  Self^.Parent.VMT := @mTTermRuleNode_AST;
  Self^.TermRuleId := 0; 
  Self^.Nfa := nil;
  Self^.CommandList := TList_Create(SizeOf(TCommand), 1);
End;

Procedure TTermRuleNode_Destroy(Self: PAstNode);
Var
  I: TSize;
  mElem: PCommand;
  mSelf: PTermRuleNode;
Begin
  mSelf := PTermRuleNode(Self);
  If mSelf^.Nfa <> nil Then { only for non-empty rule. }
  Begin
    TNfa_Destroy(mSelf^.Nfa);
  End;
  If Not TList_IsEmpty(mSelf^.CommandList) Then
  Begin
    For I := 0 To Pred(mSelf^.CommandList^.Size) Do
    Begin
      mElem := PCommand(TList_Get(mSelf^.CommandList, I));
      If mElem^.Arg <> nil Then
      Begin
        FreeStr(mElem^.Arg);
      End;
    End;
  End;
  TList_Destroy(mSelf^.CommandList);
  TAstNode_Destroy(Self);
End;

Procedure TTermRuleNode_Accept(Self: PAstNode; Visitor: PAstVisitor);
Begin
  Visitor^.Methods^.VisitTermRule(Visitor, Self);
End;

Procedure TTermRuleNode_AddSkipCommand(Self: PTermRuleNode);
Var
  mCommand: PCommand;
Begin
  mCommand := PCommand(TList_EmplaceBack(Self^.CommandList));
  mCommand^.CommandType := eSkipCommand;
  mCommand^.Arg := nil;
End;

Procedure TTermRuleNode_AddPushModeCommand(Self: PTermRuleNode; Mode: PChar);
Var
  mCommand: PCommand;
Begin
  mCommand := PCommand(TList_EmplaceBack(Self^.CommandList));
  mCommand^.CommandType := ePushModeCommand;
  mCommand^.Arg := StrNew(Mode);
End;

Procedure TTermRuleNode_AddPopModeCommand(Self: PTermRuleNode);
Var
  mCommand: PCommand;
Begin
  mCommand := PCommand(TList_EmplaceBack(Self^.CommandList));
  mCommand^.CommandType := ePopModeCommand;
  mCommand^.Arg := nil;
End;

Begin
  mTTermRuleNode_AST.Destory := TTermRuleNode_Destroy;
  mTTermRuleNode_AST.Accept := TTermRuleNode_Accept;
End.
