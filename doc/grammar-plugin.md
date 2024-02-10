# Grammar PlugIn

When using a grammar file, ASTBuilder may use a corresponding plugin dynamic library for parsing. ASTBuilder will invoke the plugin's functions during initialization and parsing each token. ASTBuilder will pass a context record with some useful callback functions as the parameter to those plugin's functions, so that the plugin can use those callback functions to use ASTBuilder provided functionalities.

## PlugIn Interface

```pascal
  TRegisterTermRule = Procedure(Name: PChar);
  TGetMode = Function: PChar;
  TGetTokenKind = Function: PChar;
  TGetTokenValue = Function: PChar;
  TInsertToken = Procedure(Kind: PChar; Value: PChar);
  TPopMode = Procedure;

  PContext = ^TContext;

  TContext = Record
    RegisterTermRule: TRegisterTermRule;
    GetMode: TGetMode;
    GetTokenKind: TGetTokenKind;
    GetTokenValue: TGetTokenValue;
    InsertToken: TInsertToken;
    PopMode: TPopMode;
  End;

  Procedure Init(Context: PContext);
  Procedure ProcessToken(Context: PContext);
```

### `Init`

This function will be called during ASTBuilder's initialization. You can use this function to initialize some global variables.

### `ProcessToken`

This function will be called for each token during parsing. You can use this function to process the token and generate AST nodes.

### `RegisterTermRule`

This function will be called for each term rule during parsing. You can use this function to register a term rule.

### `GetMode`

This function will be called to get the current parsing mode.

### `GetTokenKind`
This function will be called to get the kind of the current token.

### `GetTokenValue`

This function will be called to get the value of the current token.

### `InsertToken`

This function will be called to insert a new token into the token stream.

### `PopMode`

This function will be called to pop the current parsing mode.
