#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
plugin_source_dir="$repo_root/Test/TestCase/pascal"
vim_home="${VIM_HOME:-$HOME/.vim}"
fpc="${FPC:-fpc}"
cc="${CC:-cc}"

if ! command -v "$fpc" >/dev/null 2>&1; then
    echo "Free Pascal Compiler (fpc) is required to build ASTBuilder." >&2
    exit 1
fi
if ! command -v "$cc" >/dev/null 2>&1; then
    echo "A C compiler (cc) is required to build the grammar plugin." >&2
    exit 1
fi

build_dir="$(mktemp -d "${TMPDIR:-/tmp}/astbuilder-vim.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT

case "$(uname -s)" in
    Darwin)
        plugin_name="libpascal.dylib"
        "$cc" -std=c11 -Wall -Wextra -Werror -fPIC -dynamiclib \
            -I"$plugin_source_dir" "$plugin_source_dir/library.c" \
            -o "$build_dir/$plugin_name"
        ;;
    Linux)
        plugin_name="libpascal.so"
        "$cc" -std=c11 -Wall -Wextra -Werror -fPIC -shared \
            -I"$plugin_source_dir" "$plugin_source_dir/library.c" \
            -o "$build_dir/$plugin_name"
        ;;
    *)
        echo "Unsupported platform: $(uname -s)" >&2
        exit 1
        ;;
esac

"$fpc" \
    -Fi"$repo_root" \
    -Fu"$repo_root/Util" \
    -Fu"$repo_root/AST" \
    -Fu"$repo_root/Automata" \
    -Fu"$repo_root/LEXER" \
    -Fu"$repo_root/LexrRule/Grammar" \
    -Fu"$repo_root/LexrRule/Template" \
    -Fu"$repo_root/PARSER" \
    -Fu"$repo_root/ParseTr" \
    -Fu"$repo_root/ProdRule" \
    -Fu"$repo_root/Test" \
    -FE"$build_dir" \
    -FU"$build_dir" \
    "$repo_root/ASTBuilder.lpr"

mkdir -p "$vim_home/syntax" "$vim_home/astbuilder" "$vim_home/ftdetect"
mkdir -p /tmp/pascal_ast_1
cp "$script_dir/syntax/pascal.vim" "$vim_home/syntax/"
cp "$repo_root/Test/TestCase/pascal.xg" "$vim_home/astbuilder/pascal.xg"
cp "$build_dir/ASTBuilder" "$vim_home/astbuilder/ASTBuilder"
cp "$build_dir/$plugin_name" "$vim_home/astbuilder/$plugin_name"
cp "$script_dir/ftdetect/pascal.vim" "$vim_home/ftdetect/"

touch "$HOME/.vimrc"
grep -Fxq 'syntax on' "$HOME/.vimrc" || printf '%s\n' 'syntax on' >> "$HOME/.vimrc"
grep -Fxq 'filetype on' "$HOME/.vimrc" || printf '%s\n' 'filetype on' >> "$HOME/.vimrc"

printf 'Installed ASTBuilder and %s into %s/astbuilder\n' "$plugin_name" "$vim_home"
