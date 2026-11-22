# ASTBuilder-based Vim Syntax Plugin for Pascal

This directory contains a syntax highlighting plugin for Pascal files that uses ASTBuilder for parsing and token extraction.

## Features

- **AST-based syntax highlighting**: Uses ASTBuilder to generate AST from Pascal code
- No regex patterns for keyword matching - highlights are defined by actual AST token names
- Support for all Pascal keywords, operators, comments, and literals
- Proper handling of both `(* comment *)` and `{ comment }` style comments
- **Plugin library**: Includes a sample grammar plugin for heredoc support

## Requirements

- Free Pascal Compiler (`fpc`) to build ASTBuilder
- A C compiler (`cc`) to build the grammar plugin
- Vim

## Installation

Run `./install.sh` from this directory. The script builds ASTBuilder and the
encoding-aware C grammar plugin from this repository, then installs them with
the Pascal syntax and file-detection scripts under `~/.vim`.

## How It Works

The plugin works by:

1. Running ASTBuilder to parse the Pascal code and generate AST files
2. Reading the AST output (.xnr, .xtr, .xs, .xt files)
3. Extracting token information from the AST
4. Defining syntax highlighting groups based on EXACT token names from AST
5. Applying appropriate colors through highlight links

## Usage

1. Open a Pascal file: `vim test.pas`
2. The plugin will:
   - Run ASTBuilder to generate AST
   - Parse the AST and define syntax groups from actual tokens
   - Apply syntax highlighting

## Configuration

### ASTBuilder Path
```vim
let g:pascal_astbuilder_path = "/path/to/ASTBuilder"
```

### Grammar File Path
```vim
let g:pascal_grammar_file = "/path/to/pascal.xg"
```

### Plugin Path (for custom grammar plugins)
```vim
let g:pascal_plugin_path = "/path/to/libpascal.so"
```

## Files

- `syntax/pascal.vim` - Main syntax file (AST-based highlighting)
- `README.md` - This documentation

## AST Output Files

The plugin generates temporary AST files:
- `pascal_ast_<bufnr>.xnr` - Non-terminal rules
- `pascal_ast_<bufnr>.xtr` - Terminal rules  
- `pascal_ast_<bufnr>.xs` - Code string
- `pascal_ast_<bufnr>.xt` - Parse tree

These files are automatically cleaned up after highlighting is applied.

## Notes

- The installer builds the current ASTBuilder executable and `libpascal`
  (`.dylib` on macOS, `.so` on Linux); it does not use a prebuilt plugin binary.
- The parser defaults to UTF-8. Set the global encoding in the application
  before parsing to test another encoding.
- For Heredoc support, ensure your grammar includes START_HEREDOC and HEREDOC_TEXT rules
- All highlighting is derived from AST token names, not regex patterns

## Known Issues

- Other custom grammar plugins may still trigger ASTBuilder failures; this
  installer rebuilds the in-repository Pascal example plugin.
- Basic Pascal syntax highlighting can work without a grammar plugin.

## License

Same as Vim.
