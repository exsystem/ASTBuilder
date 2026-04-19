#!/bin/bash

cp syntax/pascal.vim ~/.vim/syntax/
#cp syntax/pascal_v7_compat.vim ~/.vim/syntax/pascal.vim
cp ../ASTBuilder ~/.vim/astbuilder/
cp ../../Grammar/pascal/pascal.xg ~/.vim/astbuilder/
cp ../../Grammar/pascal/pascal/libpascal.dylib ~/.vim/astbuilder/
mkdir -p /tmp/pascal_ast_1/
#rm -f ~/.vim/astbuilder/gen_highlights.py
#vim ../Test/vim-zh.pas
