#!/bin/bash

cp syntax/pascal.vim ~/.vim/syntax/
#cp syntax/pascal-v7.vim ~/.vim/syntax/pascal.vim
cp ../ASTBuilder ~/.vim/astbuilder/
cp ../../Grammar/pascal/pascal.xg ~/.vim/astbuilder/
cp ../../Grammar/pascal/pascal/libpascal.dylib ~/.vim/astbuilder/
mkdir -p /tmp/pascal_ast_1/
#rm -f ~/.vim/astbuilder/gen_highlights.py
#vim ../Test/vim-zh.pas
