# AST Generation Code Pattern
## `E -> A B C ...`
### Psudo code
```pascal
Function E(): Boolean;
Begin
  Result := A() And B() And C() { And ... }; 
End;
```
### Actual pattern example
```pascal
// OR 1:
If Not TParser_Term(Parser, eLParent) Then
Begin
  // IF FALSE on 1:
  Parser.Error := '( expected.';
  Ast := nil;
  // RETURN FALSE:
  Result := False;
  Exit;
End;
// OR 2:
If Not ExprRuleUnit.ExprRule(Parser, mNewNode) Then
Begin
  // IF FALSE on 2:
  Parser.Error := 'Expression expected.';
  // RETURN FALSE:
  Result := False;
  Exit;
End;
// OR 3:
If Not TParser_Term(Parser, eRParent) Then
Begin
  // IF FALSE on 3:
  Parser.Error := ') expected.';
  Ast := nil;
  // RETURN FALSE:
  Result := False;
  Exit;
End;
// IF TRUE:
Ast := mNewNode;
// RETURN TRUE:
Result := True;
```
## `E -> A | B | C ...`
### Psudo code
```pascal
Function E(): Boolean;
Begin
  Result := A() Or B() Or C() { Or ... }; 
End;
```
### Actual pattern example
```pascal
// Initilization
New(PBinaryOpNode(Ast));
TBinaryOpNode_Create(PBinaryOpNode(Ast));
// OR 1
If TParser_Term(Parser, eMul) Then
Begin
  // IF TRUE on 1:
  PBinaryOpNode(Ast).OpType := eMultiply;
  // RETURN TRUE:
  Result := True;
  Exit;
End;
// OR 2
If TParser_Term(Parser, eSlash) Then
Begin
  // IF TRUE on 2:
  PBinaryOpNode(Ast).OpType := eRealDivide;
  // RETURN TRUE:
  Result := True;
  Exit;
End;
// IF FALSE:
TBinaryOpNode_Destroy(Ast);
Dispose(PBinaryOpNode(Ast));
Ast := nil;
Parser.Error := 'Multiplicative operator expected.';
// RETURN FALSE:
Result := False;
```
## `E -> X ( A B ) *`
### Actual pattern example
```pascal
// PREPARE NODE FOR X
If Not RelFactorRule(Parser, mRightNode) Then
Begin
  // IF FALSE:
  Parser.Error := 'Relational expression expected.';
  Ast := nil;
  // RETURN FALSE:
  Result := False;
  Exit;
End;

// HEAD NODE INITIALIZATION
New(mHeadNode);
TBinaryOpNode_Create(mHeadNode);
mCurrNode := mHeadNode;
// SET NODE FROM X
mCurrNode.RightNode := mRightNode;

// LOOP FOR: ( A B ) *
Result := True;
// FOR EACH LOOP TERM ( A B ):
While Not TParser_Term(Parser, eEof) Do
Begin
  // BACKUP FOR FALLBACK TO X:
  mSavePoint := Parser.FCurrentToken;
  
  // AND FOR A:
  If Not RelOpRule(Parser, PAstNode(mNewNode)) Then
  Begin
    // FALLBACK IF FALSE ON A INSIDE CURRENT LOOP TERM ( A B )
    Parser.FCurrentToken := mSavePoint;
    Break;
  End;
  // AND FOR B:
  If Not RelFactorRule(Parser, mRightNode) Then
  Begin
    // FALLBACK IF FALSE ON B INSIDE CURRENT LOOP TERM ( A B )
    Parser.FCurrentToken := mSavePoint;
    Break;
  End;

  // IF TRUE FOR CURRENT LOOP TERM ( A B ):
  mNewNode.LeftNode := mCurrNode.RightNode;
  mNewNode.RightNode := mRightNode;
  mCurrNode.RightNode := PAstNode(mNewNode);
End;

// IF TRUE:
Ast := mHeadNode.RightNode;
mHeadNode.RightNode := nil;
TBinaryOpNode_Destroy(PAstNode(mHeadNode));
Dispose(mHeadNode);
```