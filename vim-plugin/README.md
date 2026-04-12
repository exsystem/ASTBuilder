# ASTBuilder-based Vim Syntax Plugin for Pascal

This directory contains a syntax highlighting plugin for Pascal files that uses ASTBuilder for parsing and token extraction.

## Features

- **AST-based syntax highlighting**: Uses ASTBuilder to generate AST from Pascal code
- No regex patterns for keyword matching - highlights are defined by actual AST token names
- Support for all Pascal keywords, operators, comments, and literals
- Proper handling of both `(* comment *)` and `{ comment }` style comments
- **Plugin library**: Includes a sample grammar plugin for heredoc support

## Requirements

- ASTBuilder executable
- A grammar plugin library (.dylib on macOS, .so on Linux)

## Installation

1. Copy the contents of this directory to your Vim syntax directory:
   - Unix/Linux: `~/.vim/syntax/`
   - macOS: `~/Library/Vim/syntax/`
   - Windows: `vimfiles\syntax\`

2. Or if using a plugin manager like vim-plug, add:
   ```vim
   Plug 'path/to/this/directory'
   ```

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

- The plugin requires ASTBuilder to be installed and accessible
- For Heredoc support, ensure your grammar includes START_HEREDOC and HEREDOC_TEXT rules
- All highlighting is derived from AST token names, not regex patterns

## Known Issues

- ASTBuilder may crash with an access violation when using certain grammar plugins (issue in ASTBuilder itself)
- The pre-built `libpascal.dylib` from the Grammar directory may cause crashes with some test files
- As a workaround, syntax highlighting can still work without the grammar plugin for basic Pascal files

## License

Same as Vim.
