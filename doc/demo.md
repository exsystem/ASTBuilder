# Demo

This will demostrate the process of parsing a sample code using a modified PASCAL grammar with HEREDOC support, similar as what PHP does. You write the grammar file, make the corresponding grammar plugin dynamic library, and provide your sample code to ASTBuilder to generate the AST in binary format, then you write a program to convert this binary format AST into a graphviz DOT file, and use the graphviz tool to generate the visualized AST tree. Although ASTBuilder is written in PASCAL, you can also use any other language that supports dynamic library to write your grammar plugin, in this case let's use C++ and C to accomplish our demo.

## Grammar File

Save the following grammar content into a file named `pascal.xg`.

```
options {
   caseInsensitive = true;
}

program
   : programHeading (INTERFACE)? block DOT 
   ;

programHeading
   : PROGRAM identifier (LPAREN identifierList RPAREN)? SEMI
   | UNIT identifier SEMI
   ;

identifier
   : IDENT
   ;

block
   : (labelDeclarationPart | constantDefinitionPart | typeDefinitionPart | variableDeclarationPart | procedureAndFunctionDeclarationPart | usesUnitsPart | IMPLEMENTATION)* compoundStatement
   ;

usesUnitsPart
   : USES identifierList SEMI
   ;

labelDeclarationPart
   : LABEL label (COMMA label)* SEMI
   ;

label
   : unsignedInteger
   ;

constantDefinitionPart
   : CONST (constantDefinition SEMI) +
   ;

constantDefinition
   : identifier EQUAL constant
   ;

constantChr
   : CHR LPAREN unsignedInteger RPAREN
   ;

constant
   : unsignedNumber
   | sign unsignedNumber
   | identifier
   | sign identifier
   | string
   | constantChr
   ;

unsignedNumber
   : unsignedInteger
   | unsignedReal
   ;

unsignedInteger
   : NUM_INT
   ;

unsignedReal
   : NUM_REAL
   ;

sign
   : PLUS
   | MINUS
   ;

bool_
   : TRUE
   | FALSE
   ;

string
   : STRING_LITERAL
   | START_HEREDOC HEREDOC_TEXT +
   ;

typeDefinitionPart
   : TYPE (typeDefinition SEMI) +
   ;

typeDefinition
   : identifier EQUAL (type_ | functionType | procedureType)
   ;

functionType
   : FUNCTION (formalParameterList)? COLON resultType
   ;

procedureType
   : PROCEDURE (formalParameterList)?
   ;

type_
   : simpleType
   | structuredType
   | pointerType
   ;

simpleType
   : scalarType
   | subrangeType
   | typeIdentifier
   | stringtype
   ;

scalarType
   : LPAREN identifierList RPAREN
   ;

subrangeType
   : constant DOTDOT constant
   ;

typeIdentifier
   : identifier
   | (CHAR | BOOLEAN | INTEGER | REAL | STRING)
   ;

structuredType
   : PACKED unpackedStructuredType
   | unpackedStructuredType
   ;

unpackedStructuredType
   : arrayType
   | recordType
   | setType
   | fileType
   ;

stringtype
   : STRING LBRACK (identifier | unsignedNumber) RBRACK
   ;

arrayType
   : ARRAY LBRACK typeList RBRACK OF componentType
   | ARRAY LBRACK2 typeList RBRACK2 OF componentType
   ;

typeList
   : indexType (COMMA indexType)*
   ;

indexType
   : simpleType
   ;

componentType
   : type_
   ;

recordType
   : RECORD fieldList? END
   ;

fieldList
   : fixedPart (SEMI variantPart)?
   | variantPart
   ;

fixedPart
   : recordSection (SEMI recordSection)*
   ;

recordSection
   : identifierList COLON type_
   ;

variantPart
   : CASE tag OF variant (SEMI variant)*
   ;

tag
   : identifier COLON typeIdentifier
   | typeIdentifier
   ;

variant
   : constList COLON LPAREN fieldList RPAREN
   ;

setType
   : SET OF baseType
   ;

baseType
   : simpleType
   ;

fileType
   : FILE OF type_
   | FILE
   ;

pointerType
   : POINTER typeIdentifier
   ;

variableDeclarationPart
   : VAR variableDeclaration (SEMI variableDeclaration)* SEMI
   ;

variableDeclaration
   : identifierList COLON type_
   ;

procedureAndFunctionDeclarationPart
   : procedureOrFunctionDeclaration SEMI
   ;

procedureOrFunctionDeclaration
   : procedureDeclaration
   | functionDeclaration
   ;

procedureDeclaration
   : PROCEDURE identifier (formalParameterList)? SEMI block
   ;

formalParameterList
   : LPAREN formalParameterSection (SEMI formalParameterSection)* RPAREN
   ;

formalParameterSection
   : parameterGroup
   | VAR parameterGroup
   | FUNCTION parameterGroup
   | PROCEDURE parameterGroup
   ;

parameterGroup
   : identifierList COLON typeIdentifier
   ;

identifierList
   : identifier (COMMA identifier)*
   ;

constList
   : constant (COMMA constant)*
   ;

functionDeclaration
   : FUNCTION identifier (formalParameterList)? COLON resultType SEMI block
   ;

resultType
   : typeIdentifier
   ;

statement
   : label COLON unlabelledStatement
   | unlabelledStatement
   ;

unlabelledStatement
   : structuredStatement
   | simpleStatement
   ;

simpleStatement
   : assignmentStatement
   | procedureStatement
   | gotoStatement
   | emptyStatement_
   ;

assignmentStatement
   : variable ASSIGN expression
   ;

variable
   : (AT identifier | identifier) (LBRACK expression (COMMA expression)* RBRACK | LBRACK2 expression (COMMA expression)* RBRACK2 | DOT identifier | POINTER)*
   ;

expression
   : simpleExpression (relationaloperator expression)?
   ;

relationaloperator
   : EQUAL
   | NOT_EQUAL
   | LT
   | LE
   | GE
   | GT
   | IN
   ;

simpleExpression
   : term (additiveoperator simpleExpression)?
   ;

additiveoperator
   : PLUS
   | MINUS
   | OR
   ;

term
   : signedFactor (multiplicativeoperator term)?
   ;

multiplicativeoperator
   : STAR
   | SLASH
   | DIV
   | MOD
   | AND
   ;

signedFactor
   : (PLUS | MINUS)? factor
   ;

factor
   : functionDesignator
   | LPAREN expression RPAREN
   | variable
   | unsignedConstant
   | set_
   | NOT factor
   | bool_
   ;

unsignedConstant
   : unsignedNumber
   | constantChr
   | string
   | NIL
   ;

functionDesignator
   : identifier LPAREN parameterList RPAREN
   ;

parameterList
   : actualParameter (COMMA actualParameter)*
   ;

set_
   : LBRACK elementList RBRACK
   | LBRACK2 elementList RBRACK2
   ;

elementList
   : element (COMMA element)*
   |
   ;

element
   : expression (DOTDOT expression)?
   ;

procedureStatement
   : identifier (LPAREN parameterList RPAREN)?
   ;

actualParameter
   : expression parameterwidth*
   ;

parameterwidth
   : COLON expression
   ;

gotoStatement
   : GOTO label
   ;

emptyStatement_
   :
   ;

empty_
   :
   ;

structuredStatement
   : compoundStatement
   | conditionalStatement
   | repetetiveStatement
   | withStatement
   ;

compoundStatement
   : BEGIN statements END
   ;

statements
   : statement (SEMI statement)*
   ;

conditionalStatement
   : ifStatement
   | caseStatement
   ;

ifStatement
   : IF expression THEN statement (ELSE statement)?
   ;

caseStatement
   : CASE expression OF caseListElement (SEMI caseListElement)* (SEMI ELSE statements)? END
   ;

caseListElement
   : constList COLON statement
   ;

repetetiveStatement
   : whileStatement
   | repeatStatement
   | forStatement
   ;

whileStatement
   : WHILE expression DO statement
   ;

repeatStatement
   : REPEAT statements UNTIL expression
   ;

forStatement
   : FOR identifier ASSIGN forList DO statement
   ;

forList
   : initialValue (TO | DOWNTO) finalValue
   ;

initialValue
   : expression
   ;

finalValue
   : expression
   ;

withStatement
   : WITH recordVariableList DO statement
   ;

recordVariableList
   : variable (COMMA variable)*
   ;

AND
   : 'AND'
   ;


ARRAY
   : 'ARRAY'
   ;


BEGIN
   : 'BEGIN'
   ;


BOOLEAN
   : 'BOOLEAN'
   ;


CASE
   : 'CASE'
   ;


CHAR
   : 'CHAR'
   ;


CHR
   : 'CHR'
   ;


CONST
   : 'CONST'
   ;


DIV
   : 'DIV'
   ;


DOWNTO
   : 'DOWNTO'
   ;


DO
   : 'DO'
   ;


ELSE
   : 'ELSE'
   ;


END
   : 'END'
   ;


FILE
   : 'FILE'
   ;


FOR
   : 'FOR'
   ;


FUNCTION
   : 'FUNCTION'
   ;


GOTO
   : 'GOTO'
   ;


IF
   : 'IF'
   ;


IN
   : 'IN'
   ;


INTEGER
   : 'INTEGER'
   ;


LABEL
   : 'LABEL'
   ;


MOD
   : 'MOD'
   ;


NIL
   : 'NIL'
   ;


NOT
   : 'NOT'
   ;


OF
   : 'OF'
   ;


OR
   : 'OR'
   ;


PACKED
   : 'PACKED'
   ;


PROCEDURE
   : 'PROCEDURE'
   ;


PROGRAM
   : 'PROGRAM'
   ;


REAL
   : 'REAL'
   ;


RECORD
   : 'RECORD'
   ;


REPEAT
   : 'REPEAT'
   ;


SET
   : 'SET'
   ;


THEN
   : 'THEN'
   ;


TO
   : 'TO'
   ;


TYPE
   : 'TYPE'
   ;


UNTIL
   : 'UNTIL'
   ;


VAR
   : 'VAR'
   ;


WHILE
   : 'WHILE'
   ;


WITH
   : 'WITH'
   ;


PLUS
   : '+'
   ;


MINUS
   : '-'
   ;


STAR
   : '*'
   ;


SLASH
   : '/'
   ;


ASSIGN
   : ':='
   ;


COMMA
   : ','
   ;


SEMI
   : ';'
   ;


COLON
   : ':'
   ;


EQUAL
   : '='
   ;

START_HEREDOC
   : '<<<' [a-zA-Z_][a-zA-Z0-9_]* -> pushMode(hereDoc) ;

NOT_EQUAL
   : '<>'
   ;


LT
   : '<'
   ;


LE
   : '<='
   ;


GE
   : '>='
   ;


GT
   : '>'
   ;


LPAREN
   : '('
   ;


RPAREN
   : ')'
   ;


LBRACK
   : '['
   ;


LBRACK2
   : '(.'
   ;


RBRACK
   : ']'
   ;


RBRACK2
   : '.)'
   ;


POINTER
   : '^'
   ;


AT
   : '@'
   ;


DOT
   : '.'
   ;


DOTDOT
   : '..'
   ;

   
UNIT
   : 'UNIT'
   ;


INTERFACE
   : 'INTERFACE'
   ;


USES
   : 'USES'
   ;


STRING
   : 'STRING'
   ;


IMPLEMENTATION
   : 'IMPLEMENTATION'
   ;


TRUE
   : 'TRUE'
   ;


FALSE
   : 'FALSE'
   ;


WS
   : [ \t\r\n] ->skip
   ;


COMMENT_1
   : '(*' .*? '*)' ->skip
   ;


COMMENT_2
   : '{' .*? '}' ->skip
   ;


IDENT
   : ('A' .. 'Z') ('A' .. 'Z' | '0' .. '9' | '_')*
   ;


STRING_LITERAL
   : '\'' ('\'\'' | ~ ('\''))* '\''
   ;

NUM_REAL
   : ('0' .. '9') + (('.' ('0' .. '9') + ('E' ('+' | '-')? ('0' .. '9') + )?) | 'E' ('+' | '-')? ('0' .. '9') +)
   ;

NUM_INT
   : ('0' .. '9') +
   ;


mode hereDoc;
HEREDOC_TEXT: (~([\r\n]))* [\r\n];
```

## Sample Input Code File

Use this following code as input to ASTBuilder, save it as `test.pp`.

```pascal
Program TEST;

Var
  mFoo: Byte;
  mBar: String;
Begin
  {hello}
  If (mFoo > 12.345) Or (mBar = 'test') Then
  Begin
    mBar := <<<barbar
function foo(x: Integer): String;
begin
  if (mFoo > 345.12) or (mBar = 'haha') then 
  begin
    result := 'whatever'; 
  end;
  result := <<<foo
.... :-) ....
foo;
end;
barbar;
    For I := 100 Downto -100 Do
    Begin
      P := Func1(I);
    End;
    ReAdLn;
    WriteLn('hello {this is not comment at all {{{}}}}' + ' byebye');
  End;
  ExIt;
  {byebye}
End.
```

## Grammar Plugin

In this demo, the plugin is written in C. First, create a file named `astbuilder.h` with this content.

```c
#ifndef ASTBUILDER_H
#define ASTBUILDER_H 

typedef void (*TRegisterTermRule)(char *Name);

typedef char *(*TGetMode)(void);

typedef char *(*TGetTokenKind)(void);

typedef char *(*TGetTokenValue)(void);

typedef void (*TInsertToken)(char *Kind, char *Value);

typedef void (*TPopMode)(void);

typedef struct TContext *PContext;

struct TContext {
    TRegisterTermRule RegisterTermRule;
    TGetMode GetMode;
    TGetTokenKind GetTokenKind;
    TGetTokenValue GetTokenValue;
    TInsertToken InsertToken;
    TPopMode PopMode;
};

#endif //ASTBUILDER_H
```

Next, create a file named `library.h` with this content.

```c
#ifndef PASCAL_LIBRARY_H
#define PASCAL_LIBRARY_H
#include "astbuilder.h"

void Init(const struct TContext* Context);
void ProcessToken(const struct TContext* Context);

#endif //PASCAL_LIBRAR
```

Finally, create a file named `astbuilder.c` with this content.

```c
#include "library.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void Init(const struct TContext *Context) {
    Context->RegisterTermRule("@HEREDOC_END");
}

void ProcessToken(const struct TContext *Context) {
    const char *mode = Context->GetMode();
    const char *token_value = Context->GetTokenValue();
    const char *token_kind = Context->GetTokenKind();
    static char *here_doc_id;
    if (strcmp(mode, "hereDoc") != 0) {
        return;
    }
    if (strcmp(token_kind, "START_HEREDOC") == 0) {
        here_doc_id = (char *) malloc(strlen(token_value) - 3);
        strncpy(here_doc_id, token_value + 3, strlen(token_value) - 3);
        return;
    }
    if (strcmp(token_kind, "HEREDOC_TEXT") == 0 && strstr(token_value, here_doc_id) == token_value) {
        Context->InsertToken("@HEREDOC_END", here_doc_id);
        Context->PopMode();
        free(here_doc_id);
    }
}
```

Then, compile the plugin with those source code files into a dynamic library file, such as `libpascal.dylib` on macOS, `libpascal.so` on Linux, or `pascal.dll` on Windows.

## Converter Program for Converting AST to Graphviz DOT File

In this demo, we use C++ to write the converter program for converting the AST to a graphviz DOT file. Please compile this source code (under **C++17** standard) into the executable file called `tree-builder` on MacOS/Linux or `tree-builder.exe` on Windows.

```cpp
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

using namespace std;

struct Node {
    uint64_t parent;
    uint64_t rule_id;
    uint64_t token_kind_id;
    uint64_t start_pos;
    uint64_t str_offset;
};

vector<string> &parse_strings(const string &filename) {
    ifstream file(filename, ios::in);
    char ch;
    const auto result = new vector<string>();
    string str;
    while (file.get(ch)) {
        if (ch == '\0') {
            result->push_back(move(str));
            continue;
        }
        str += ch;
    }
    file.close();
    return *result;
}

vector<Node> &parse_nodes(const string &filename) {
    ifstream file(filename, ios::binary);
    const auto result = new vector<Node>();
    while (!file.eof()) {
        Node &node = result->emplace_back();
        file.read(reinterpret_cast<char *>(&node), sizeof(Node));
    }
    file.close();
    return *result;
}

string &parse_string(const string &filename) {
    ifstream file(filename, ios::in);
    stringstream buffer;
    buffer << file.rdbuf();
    file.close();
    const auto result = new string(buffer.str());
    return *result;
}

void build_graph(const vector<string> &non_term_rules, const vector<string> &term_rules, const string &code_string,
                 const vector<Node> &tree, const string &filename) {
    ofstream file(filename, ios::trunc);
    file << "graph \"\"" << endl;
    file << "{" << endl;
    file << "ordering=\"out\"" << endl;
    uint64_t i = 0;
    for (auto node_it = tree.begin(); node_it != prev(tree.end()); ++node_it, ++i) {
        stringstream node;
        node << "n" << i;
        stringstream label_content;
        if (node_it->rule_id == 0) {
            label_content << term_rules[node_it->token_kind_id];
            label_content << ": ";
            label_content << node_it->start_pos;
            label_content << " \\n ";
            auto tmp = code_string.substr(node_it->str_offset,
                                          (node_it + 1)->str_offset - node_it->str_offset);
            replace(tmp.begin(), tmp.end(), '\n', ' ');
            replace(tmp.begin(), tmp.end(), '\r', ' ');
            label_content << tmp;
        } else {
            label_content << non_term_rules[node_it->rule_id];
        }
        stringstream parent_node;
        parent_node << "n" << node_it->parent;

        file << node.str() << " ;" << endl;
        file << node.str() << "[label=\"" << label_content.str() << "\"] ;" << endl;
        if (node_it == tree.begin()) continue;
        file << parent_node.str() << " -- " << node.str() << "; " << endl;
    }
    file << "}" << endl;
    file.flush();
    file.close();
}

int main() {
    string non_term_rules_filename, term_rules_filename, tree_filename, string_filename, graphviz_dot_filename;
    cout <<
            "[non_term_rules_filename (*.xnr), term_rules_filename (*.xtr), string_filename (*.xs), tree_filename (*.xt), graphviz_dot_filename (*.dot)]?"
            <<
            endl;
    cin >> non_term_rules_filename >> term_rules_filename >> string_filename >> tree_filename >> graphviz_dot_filename;
    const auto &non_term_rules = parse_strings(non_term_rules_filename);
    for (int i = 0; i < non_term_rules.size(); ++i) {
        cout << i << ": " << non_term_rules[i] << endl;
    }
    const auto &term_rules = parse_strings(term_rules_filename);
    for (int i = 0; i < term_rules.size(); ++i) {
        cout << i << ": " << term_rules[i] << endl;
    }
    const auto &tree = parse_nodes(tree_filename);
    for (int i = 0; i < tree.size(); ++i) {
        cout << i << ": parent=" << tree[i].parent << ", rule_id=" << tree[i].rule_id << ", token_kind_id=" << tree[i].
                token_kind_id << ", start_pos=" << tree[i].start_pos << ", str_offset=" << tree[i].str_offset << endl;
    }
    const auto &string = parse_string(string_filename);
    cout << string << endl;

    build_graph(non_term_rules, term_rules, string, tree, graphviz_dot_filename);

    delete &non_term_rules;
    delete &term_rules;
    delete &string;
    delete &tree;
    return 0;
}
```

## Usage

1. Run ASTBuilder to generate the AST.
```bash
$ ./ASTBuilder pascal.xg test.pp pascal_ libpascal.dylib
```
2. Convert the AST to the DOT file using the converter program we just made.
```bash
$ ./tree-builder
```
When prompted like this, 
```
[non_term_rules_filename (*.xnr), term_rules_filename (*.xtr), string_filename (*.xs), tree_filename (*.xt), graphviz_dot_filename (*.dot)]?
```
enter the following:
```
pascal_ast.xnr
pascal_ast.xtr
pascal_ast.xs
pascal_ast.xt
pascal_ast.dot
```
3. Generate the final visualized AST in SVG format via the DOT file using Graphviz.
```bash
$ dot -Tsvg -o pascal_ast.svg pascal_ast.dot
```