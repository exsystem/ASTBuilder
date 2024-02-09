# AST Structure

## Terminal Values Files (*.xt)

The terminal values file stores the string values of all terminals from the input code file, except all the terminals matching by a terminal rule marked as skipped. All the terminal values are followed one by one without any delimiter charcaters. Since each terminal can be indicated by a start position and a length offset, there is no need to put a `NUL`(`#0`) character at the end of the file.

```
+---------------------+---------------------+---------------------+     +---------------------+
| Value of Terminal 0 | Value of Terminal 1 | Value of Terminal 2 | ... | Value of Terminal N |
+---------------------+---------------------+---------------------+     +---------------------+
```

## Non-terminal Rules Files (*.xnr)

This file contains the rule names of all non-terminals defined in your grammar and used in the input code file. Each non-terminal is stored one by one in C-styled string, so you can distinguish each one by the ending `NUL`(`#0`) character. The ID of a non-terminal rule is its order number among this sequence of the rule name strings.
The first two non-terminal rules with ID `0` and `1` are always named as empty and `*`, which are the unused dummy rule and the root grammar rule (named `*`) of your grammar.
```
+-----------------------------+----+-----------------------------+----+-----------------------------+----+     +-----------------------------+----+
| Name of Non-terminal Rule 0 | #0 | Name of Non-terminal Rule 1 | #0 | Name of Non-terminal Rule 2 | #0 | ... | Name of Non-terminal Rule N | #0 |
+-----------------------------+----+-----------------------------+----+-----------------------------+----+     +-----------------------------+----+
```


## Terminal Rules Files (*.xtr)

This file contains the rule names of all terminal rules defined in your grammar and used in the input code file. Each terminal rule is stored one by one in C-styled string, so you can distinguish each one by the ending `NUL`(`#0`) character. The ID of a terminal rule is its order number among this sequence of the rule name strings.
The first two terminal rules with ID `0` and `1` are always named as empty and `EOF`, which are the unused dummy rule and the end symbol EOF of your input code.
```
+-------------------------+----+-------------------------+----+-------------------------+----+     +-------------------------+----+
| Name of Terminal Rule 0 | #0 | Name of Terminal Rule 1 | #0 | Name of Terminal Rule 2 | #0 | ... | Name of Terminal Rule N | #0 |
+-------------------------+----+-------------------------+----+-------------------------+----+     +-------------------------+----+
```

## AST Files (*.xt)

The AST files store the abstract syntax tree of the input code file. The files consist of a sequence of nodes. There are 5 fields of each node:

1. Parent Node ID: the parent node ID of the node. The ID of a node is the order number among the sequence of the nodes in the AST file.
2. Non-terminal Rule ID: the ID of the non-terminal rule, if it is a non-terminal node. A non-zero value in this field means it is a non-terminal node, otherwise it is a terminal node.
3. Terminal Rule ID: the ID of the terminal rule, if it is a terminal node. This field is ignored if it is a non-terminal node.
4. Start Position: the start character position in the input code file, indicating the value of the node, if it is a terminal node. This field is ignored if it is a non-terminal node.
5. Offset: the start character position in the terminal values file of the node, if it is a terminal node. You can retrive the string using this start position and the next nearest `NUL`(`#0`) character. This field is ignored if it is a non-terminal node.

Each field is an unsigned integer. The length of an integer is indicated by the Parent Node ID field of the first node, aka the root node.

```
        +----------------------+----------------------+----------------------+----------------------+----------------------+
Node 0: |      Field Size      | Non-terminal Rule ID |   Terminal Rule ID   |    Start Position    |         Offset       | <-- Root Node (*)
        +----------------------+----------------------+----------------------+----------------------+----------------------+
Node 1: |    Parent Node ID    | Non-terminal Rule ID |   Terminal Rule ID   |    Start Position    |         Offset       |
        +----------------------+----------------------+----------------------+----------------------+----------------------+
Node 2: |    Parent Node ID    | Non-terminal Rule ID |   Terminal Rule ID   |    Start Position    |         Offset       |
        +----------------------+----------------------+----------------------+----------------------+----------------------+
                                                                  .
                                                                  .
                                                                  .
        +----------------------+----------------------+----------------------+----------------------+----------------------+
Node N: |    Parent Node ID    | Non-terminal Rule ID |   Terminal Rule ID   |    Start Position    |         Offset       | 
        +----------------------+----------------------+----------------------+----------------------+----------------------+
```
