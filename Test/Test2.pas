Unit Test2;

{$I define.inc}

Interface

Type
  PPInteger = ^PInteger;

Procedure Test();

Implementation

Uses {$IFNDEF FPC}
  {$IFDEF VER150}
  TypInfo
  {$ELSE}
  System.Rtti
  {$ENDIF}
  , {$ENDIF}
  SysUtils,
  Lexer,
  EofRule, IdRule, TermRule, LParenRule, OrRule, ColonRule, AsteriskRule,
  QuestionMarkRule, PlusRule, TildeRule,
  RParenRule, LBracketRule, RBracketRule, CharRule, StringRule,
  DoubleDotsRule, SemiRule, SkipRule, GrammarParser,
  Parser, GrammarRuleUnit, ASTNode, ParseTree, TypeDef;

Procedure Test();
Var
  mSource: String;
  mGrammarLexer: PLexer;
  {$IFDEF VER150}
  tInfo: PTypeInfo;
  {$ENDIF}
  mParser: PParser;
  mViewer: PAstViewer;

  mLexer: PLexer;
Begin
  mSource := '';
  mSource := mSource + 'program' + #13#10;
  mSource := mSource + '   : programHeading (INTERFACE)? block DOT' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'programHeading' + #13#10;
  mSource := mSource + '   : PROGRAM identifier (LPAREN identifierList RPAREN)? SEMI'
    + #13#10;
  mSource := mSource + '   | UNIT identifier SEMI' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'identifier' + #13#10;
  mSource := mSource + '   : IDENT' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'block' + #13#10;
  mSource := mSource +
    '   : (labelDeclarationPart | constantDefinitionPart | typeDefinitionPart | variableDeclarationPart | procedureAndFunctionDeclarationPart | usesUnitsPart | IMPLEMENTATION)* compoundStatement' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'usesUnitsPart' + #13#10;
  mSource := mSource + '   : USES identifierList SEMI' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'labelDeclarationPart' + #13#10;
  mSource := mSource + '   : LABEL label (COMMA label)* SEMI' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'label' + #13#10;
  mSource := mSource + '   : unsignedInteger' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'constantDefinitionPart' + #13#10;
  mSource := mSource + '   : CONST (constantDefinition SEMI) (constantDefinition SEMI)*'
    + #13#10;
  // (constantDefinition SEMI)* => +
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'constantDefinition' + #13#10;
  mSource := mSource + '   : identifier EQUAL constant' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'constantChr' + #13#10;
  mSource := mSource + '   : CHR LPAREN unsignedInteger RPAREN' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'constant' + #13#10;
  mSource := mSource + '   : unsignedNumber' + #13#10;
  mSource := mSource + '   | sign unsignedNumber' + #13#10;
  mSource := mSource + '   | identifier' + #13#10;
  mSource := mSource + '   | sign identifier' + #13#10;
  mSource := mSource + '   | string' + #13#10;
  mSource := mSource + '   | constantChr' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'unsignedNumber' + #13#10;
  mSource := mSource + '   : unsignedInteger' + #13#10;
  mSource := mSource + '   | unsignedReal' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'unsignedInteger' + #13#10;
  mSource := mSource + '   : NUM_INT' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'unsignedReal' + #13#10;
  mSource := mSource + '   : NUM_REAL' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'sign' + #13#10;
  mSource := mSource + '   : PLUS' + #13#10;
  mSource := mSource + '   | MINUS' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'bool_' + #13#10;
  mSource := mSource + '   : TRUE' + #13#10;
  mSource := mSource + '   | FALSE' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'string' + #13#10;
  mSource := mSource + '   : STRING_LITERAL' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'typeDefinitionPart' + #13#10;
  mSource := mSource + '   : TYPE (typeDefinition SEMI) (typeDefinition SEMI)*'
    + #13#10;
  // (typeDefinition SEMI)* => +
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'typeDefinition' + #13#10;
  mSource := mSource + '   : identifier EQUAL (type_ | functionType | procedureType)'
    + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'functionType' + #13#10;
  mSource := mSource + '   : FUNCTION (formalParameterList)? COLON resultType'
    + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'procedureType' + #13#10;
  mSource := mSource + '   : PROCEDURE (formalParameterList)?' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'type_' + #13#10;
  mSource := mSource + '   : simpleType' + #13#10;
  mSource := mSource + '   | structuredType' + #13#10;
  mSource := mSource + '   | pointerType' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'simpleType' + #13#10;
  mSource := mSource + '   : scalarType' + #13#10;
  mSource := mSource + '   | subrangeType' + #13#10;
  mSource := mSource + '   | typeIdentifier' + #13#10;
  mSource := mSource + '   | stringtype' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'scalarType' + #13#10;
  mSource := mSource + '   : LPAREN identifierList RPAREN' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'subrangeType' + #13#10;
  mSource := mSource + '   : constant DOTDOT constant' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'typeIdentifier' + #13#10;
  mSource := mSource + '   : identifier' + #13#10;
  mSource := mSource + '   | (CHAR | BOOLEAN | INTEGER | REAL | STRING)' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'structuredType' + #13#10;
  mSource := mSource + '   : PACKED unpackedStructuredType' + #13#10;
  mSource := mSource + '   | unpackedStructuredType' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'unpackedStructuredType' + #13#10;
  mSource := mSource + '   : arrayType' + #13#10;
  mSource := mSource + '   | recordType' + #13#10;
  mSource := mSource + '   | setType' + #13#10;
  mSource := mSource + '   | fileType' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'stringtype' + #13#10;
  mSource := mSource + '   : STRING LBRACK (identifier | unsignedNumber) RBRACK'
    + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'arrayType' + #13#10;
  mSource := mSource + '   : ARRAY LBRACK typeList RBRACK OF componentType' + #13#10;
  mSource := mSource + '   | ARRAY LBRACK2 typeList RBRACK2 OF componentType'
    + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'typeList' + #13#10;
  mSource := mSource + '   : indexType (COMMA indexType)*' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'indexType' + #13#10;
  mSource := mSource + '   : simpleType' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'componentType' + #13#10;
  mSource := mSource + '   : type_' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'recordType' + #13#10;
  mSource := mSource + '   : RECORD fieldList? END' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'fieldList' + #13#10;
  mSource := mSource + '   : fixedPart (SEMI variantPart)?' + #13#10;
  mSource := mSource + '   | variantPart' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'fixedPart' + #13#10;
  mSource := mSource + '   : recordSection (SEMI recordSection)*' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'recordSection' + #13#10;
  mSource := mSource + '   : identifierList COLON type_' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'variantPart' + #13#10;
  mSource := mSource + '   : CASE tag OF variant (SEMI variant)*' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'tag' + #13#10;
  mSource := mSource + '   : identifier COLON typeIdentifier' + #13#10;
  mSource := mSource + '   | typeIdentifier' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'variant' + #13#10;
  mSource := mSource + '   : constList COLON LPAREN fieldList RPAREN' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'setType' + #13#10;
  mSource := mSource + '   : SET OF baseType' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'baseType' + #13#10;
  mSource := mSource + '   : simpleType' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'fileType' + #13#10;
  mSource := mSource + '   : FILE OF type_' + #13#10;
  mSource := mSource + '   | FILE' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'pointerType' + #13#10;
  mSource := mSource + '   : POINTER typeIdentifier' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'variableDeclarationPart' + #13#10;
  mSource := mSource + '   : VAR variableDeclaration (SEMI variableDeclaration)* SEMI'
    + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'variableDeclaration' + #13#10;
  mSource := mSource + '   : identifierList COLON type_' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'procedureAndFunctionDeclarationPart' + #13#10;
  mSource := mSource + '   : procedureOrFunctionDeclaration SEMI' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'procedureOrFunctionDeclaration' + #13#10;
  mSource := mSource + '   : procedureDeclaration' + #13#10;
  mSource := mSource + '   | functionDeclaration' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'procedureDeclaration' + #13#10;
  mSource := mSource + '   : PROCEDURE identifier (formalParameterList)? SEMI block'
    + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'formalParameterList' + #13#10;
  mSource := mSource +
    '   : LPAREN formalParameterSection (SEMI formalParameterSection)* RPAREN' +
    #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'formalParameterSection' + #13#10;
  mSource := mSource + '   : parameterGroup' + #13#10;
  mSource := mSource + '   | VAR parameterGroup' + #13#10;
  mSource := mSource + '   | FUNCTION parameterGroup' + #13#10;
  mSource := mSource + '   | PROCEDURE parameterGroup' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'parameterGroup' + #13#10;
  mSource := mSource + '   : identifierList COLON typeIdentifier' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'identifierList' + #13#10;
  mSource := mSource + '   : identifier (COMMA identifier)*' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'constList' + #13#10;
  mSource := mSource + '   : constant (COMMA constant)*' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'functionDeclaration' + #13#10;
  mSource := mSource +
    '   : FUNCTION identifier (formalParameterList)? COLON resultType SEMI block' +
    #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'resultType' + #13#10;
  mSource := mSource + '   : typeIdentifier' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'statement' + #13#10;
  mSource := mSource + '   : label COLON unlabelledStatement' + #13#10;
  mSource := mSource + '   | unlabelledStatement' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'unlabelledStatement' + #13#10;
  mSource := mSource + '   : simpleStatement' + #13#10;
  mSource := mSource + '   | structuredStatement' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'simpleStatement' + #13#10;
  // mSource := mSource + '   : assignmentStatement' + #13#10;
  mSource := mSource + '   : procedureStatement' + #13#10;
  mSource := mSource + '   | gotoStatement' + #13#10;
  mSource := mSource + '   | emptyStatement_' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'assignmentStatement' + #13#10;
  mSource := mSource + '   : variable ASSIGN expression' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'variable' + #13#10;
  mSource := mSource + '   : identifier' + #13#10;
  // '   : (AT identifier | identifier) (LBRACK expression (COMMA expression)* RBRACK | LBRACK2 expression (COMMA expression)* RBRACK2 | DOT identifier | POINTER)*' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'expression' + #13#10;
  mSource := mSource + '   : simpleExpression (relationaloperator expression)?'
    + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'relationaloperator' + #13#10;
  mSource := mSource + '   : EQUAL' + #13#10;
  mSource := mSource + '   | NOT_EQUAL' + #13#10;
  mSource := mSource + '   | LT' + #13#10;
  mSource := mSource + '   | LE' + #13#10;
  mSource := mSource + '   | GE' + #13#10;
  mSource := mSource + '   | GT' + #13#10;
  mSource := mSource + '   | IN' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'simpleExpression' + #13#10;
  mSource := mSource + '   : term (additiveoperator simpleExpression)?' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'additiveoperator' + #13#10;
  mSource := mSource + '   : PLUS' + #13#10;
  mSource := mSource + '   | MINUS' + #13#10;
  mSource := mSource + '   | OR' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'term' + #13#10;
  mSource := mSource + '   : signedFactor (multiplicativeoperator term)?' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'multiplicativeoperator' + #13#10;
  mSource := mSource + '   : STAR' + #13#10;
  mSource := mSource + '   | SLASH' + #13#10;
  mSource := mSource + '   | DIV' + #13#10;
  mSource := mSource + '   | MOD' + #13#10;
  mSource := mSource + '   | AND' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'signedFactor' + #13#10;
  mSource := mSource + '   : (PLUS | MINUS)? factor' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'factor' + #13#10;
  mSource := mSource + '   : variable' + #13#10;
  mSource := mSource + '   | LPAREN expression RPAREN' + #13#10;
  mSource := mSource + '   | functionDesignator' + #13#10;
  mSource := mSource + '   | unsignedConstant' + #13#10;
  mSource := mSource + '   | set_' + #13#10;
  mSource := mSource + '   | NOT factor' + #13#10;
  mSource := mSource + '   | bool_' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'unsignedConstant' + #13#10;
  mSource := mSource + '   : unsignedNumber' + #13#10;
  mSource := mSource + '   | constantChr' + #13#10;
  mSource := mSource + '   | string' + #13#10;
  mSource := mSource + '   | NIL' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'functionDesignator' + #13#10;
  mSource := mSource + '   : identifier LPAREN parameterList RPAREN' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'parameterList' + #13#10;
  mSource := mSource + '   : actualParameter (COMMA actualParameter)*' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'set_' + #13#10;
  mSource := mSource + '   : LBRACK elementList RBRACK' + #13#10;
  mSource := mSource + '   | LBRACK2 elementList RBRACK2' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'elementList' + #13#10;
  mSource := mSource + '   : element (COMMA element)*' + #13#10;
  mSource := mSource + '   |' + #13#10; // | empty_ => |
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'element' + #13#10;
  mSource := mSource + '   : expression (DOTDOT expression)?' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'procedureStatement' + #13#10;
  mSource := mSource + '   : identifier (LPAREN parameterList RPAREN)?' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'actualParameter' + #13#10;
  mSource := mSource + '   : expression parameterwidth*' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'parameterwidth' + #13#10;
  mSource := mSource + '   : COLON expression' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'gotoStatement' + #13#10;
  mSource := mSource + '   : GOTO label' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'emptyStatement_' + #13#10;
  mSource := mSource + '   :' + #13#10; // : empty_ => :
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'empty_' + #13#10;
  mSource := mSource + '   :' + #13#10; // : empty_ => :
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'structuredStatement' + #13#10;
  mSource := mSource + '   : compoundStatement' + #13#10;
  mSource := mSource + '   | conditionalStatement' + #13#10;
  mSource := mSource + '   | repetetiveStatement' + #13#10;
  mSource := mSource + '   | withStatement' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'compoundStatement' + #13#10;
  mSource := mSource + '   : BEGIN statements END' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'statements' + #13#10;
  mSource := mSource + '   : statement (SEMI statement)*' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'conditionalStatement' + #13#10;
  mSource := mSource + '   : ifStatement' + #13#10;
  mSource := mSource + '   | caseStatement' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'ifStatement' + #13#10;
  mSource := mSource + '   : IF expression THEN statement ( ELSE statement)?'
    + #13#10;
  //( ELSE statement)? => (: ELSE statement)?
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'caseStatement' + #13#10;
  mSource := mSource +
    '   : CASE expression OF caseListElement (SEMI caseListElement)* (SEMI ELSE statements)? END'
    + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'caseListElement' + #13#10;
  mSource := mSource + '   : constList COLON statement' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'repetetiveStatement' + #13#10;
  mSource := mSource + '   : whileStatement' + #13#10;
  mSource := mSource + '   | repeatStatement' + #13#10;
  mSource := mSource + '   | forStatement' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'whileStatement' + #13#10;
  mSource := mSource + '   : WHILE expression DO statement' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'repeatStatement' + #13#10;
  mSource := mSource + '   : REPEAT statements UNTIL expression' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'forStatement' + #13#10;
  mSource := mSource + '   : FOR identifier ASSIGN forList DO statement' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'forList' + #13#10;
  mSource := mSource + '   : initialValue (TO | DOWNTO) finalValue' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'initialValue' + #13#10;
  mSource := mSource + '   : expression' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'finalValue' + #13#10;
  mSource := mSource + '   : expression' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'withStatement' + #13#10;
  mSource := mSource + '   : WITH recordVariableList DO statement' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + '' + #13#10;
  mSource := mSource + 'recordVariableList' + #13#10;
  mSource := mSource + '   : variable (COMMA variable)*' + #13#10;
  mSource := mSource + '   ;' + #13#10;
  mSource := mSource + 'PROGRAM: ''Program'' ;' + #13#10;
  mSource := mSource + 'BEGIN: ''Begin'' ;' + #13#10;
  mSource := mSource + 'END: ''End'' ;' + #13#10;
  mSource := mSource +
    'IDENT: (''A'' .. ''Z'') (''A'' .. ''Z'' | ''a'' .. ''z'' | ''0'' .. ''9'' | ''_'')* ;'
    + #13#10;
  mSource := mSource + 'LPAREN : ''('' ;' + #13#10;
  mSource := mSource + 'RPAREN : '')'' ;' + #13#10;
  mSource := mSource + 'DOT: ''.'' ;' + #13#10;
  mSource := mSource + 'SEMI: '';'' ;' + #13#10;
  mSource := mSource + 'NUM_INT: (''0'' .. ''9'') (''0'' .. ''9'')* ;' + #13#10;
  WriteLn('> ANTLR4 Grammar For PASCAL:');
  WriteLn(mSource);
  mGrammarLexer := TLexer_Create(PChar(mSource));
  TLexer_AddRule(mGrammarLexer, EofRule.Compose());
  TLexer_AddRule(mGrammarLexer, IdRule.Compose());
  TLexer_AddRule(mGrammarLexer, TermRule.Compose());
  TLexer_AddRule(mGrammarLexer, LParenRule.Compose());
  TLexer_AddRule(mGrammarLexer, OrRule.Compose());
  TLexer_AddRule(mGrammarLexer, ColonRule.Compose());
  TLexer_AddRule(mGrammarLexer, AsteriskRule.Compose());
  TLexer_AddRule(mGrammarLexer, QuestionMarkRule.Compose());
  TLexer_AddRule(mGrammarLexer, TildeRule.Compose());
  TLexer_AddRule(mGrammarLexer, RParenRule.Compose());
  TLexer_AddRule(mGrammarLexer, DoubleDotsRule.Compose());
  TLexer_AddRule(mGrammarLexer, CharRule.Compose());
  TLexer_AddRule(mGrammarLexer, StringRule.Compose());
  TLexer_AddRule(mGrammarLexer, LBracketRule.Compose());
  TLexer_AddRule(mGrammarLexer, RBracketRule.Compose());
  TLexer_AddRule(mGrammarLexer, PlusRule.Compose());
  TLexer_AddRule(mGrammarLexer, TildeRule.Compose());
  TLexer_AddRule(mGrammarLexer, SemiRule.Compose());
  TLexer_AddRule(mGrammarLexer, SkipRule.Compose());

  mParser := TParser_Create(mGrammarLexer, GrammarRule);
  If TParser_Parse(mParser) Then
    WriteLn('ACCEPTED')
  Else
  Begin
    WriteLn(Format('ERROR: Parser Message: %s', [mParser.Error]));
    WriteLn(Format('ERROR: Current Token at Pos = %d, Value = [%s], Message: %s',
      [mGrammarLexer.CurrentToken.StartPos, mGrammarLexer.CurrentToken.Value,
      mGrammarLexer.CurrentToken.Error]));
  End;

  mLexer := TLexer_Create('Program Test; Begin WriteLn; ReadLn End.', False);
  TAstViewer_Create(mViewer, mLexer);
  mParser.Ast.VMT.Accept(mParser.Ast, PAstVisitor(mViewer));
  mViewer.Level := 0;
  WriteLn(mViewer.Error);
  TAstViewer_PrintParseTree(PAstVisitor(mViewer), mViewer.FParseTree);
  TParseTree_Destroy(mViewer.FParseTree);
  TAstViewer_Destroy(PAstVisitor(mViewer));
  Dispose(mViewer);
  TLexer_Destroy(mLexer);
  TParser_Destroy(mParser);
  TLexer_Destroy(mGrammarLexer);
  ReadLn;
End;

End.
