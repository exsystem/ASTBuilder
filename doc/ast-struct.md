# AST Structure

## Code Strings Files (*.xs)

The code strings file stores the strings of all terminals from the input code file, except all the skipped terminals. All the terminals are stored one by one without any delimiter. Each terminal can be indicated by a start position and a length offset. There is no need to put a `NUL`(`#0`) character at the end of the file.

## Non-terminal Rules Files (*.xnr)

This file contains the rule names of all non-terminals defined in your grammar and used in the input code file. Each non-terminal is stored one by one in C-styled string, so you can distinguish each one by the ending `NUL`(`#0`) character. The ID of a non-terminal rule is its order number among this sequence of the rule name strings.

## Terminal Rules Files (*.xtr)

This file contains the rule names of all terminal rules defined in your grammar and used in the input code file. Each terminal rule is stored one by one in C-styled string, so you can distinguish each one by the ending `NUL`(`#0`) character. The ID of a terminal rule is its order number among this sequence of the rule name strings.

## AST Files (*.xt)

The AST files store the abstract syntax tree of the input code file. The files consist of a sequence of nodes. There are 5 fields of each node:

1. Parent: the parent node ID of the node. The ID of a node is the order number among the sequence of the nodes in the AST file.
2. Non-terminal Rule ID: the ID of the non-terminal rule, if it is a non-terminal node.
3. Terminal Rule ID: the ID of the terminal rule, if it is a terminal node.
4. Start Position: the start character position in the corresponding code strings file, indicating the value of the node, if it is a terminal node.
5. String Offset: the length of the value of the node, if it is a terminal node.

Each field is an unsigned integer. The length of an integer is indicated by the Parent field of the first node, aka the root node.

