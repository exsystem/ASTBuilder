#!/bin/bash

LAZBUILD="../FPCUPdeluxe/lazarus/lazbuild"
PROJECT="./ASTBuilder.lpi"

# Modify .lpr file in order to avoid nothing-to-do-bug (http://lists.lazarus.freepascal.org/pipermail/lazarus/2016-February/097554.html)
# echo. >> "./ASTBuilder.lpr"

if [ $1 = "clean" ] || [ $1 == "test" ]; then
    find . -type f -name "*.pas" -exec ../jcf/JCF -config=./.vscode/jcfsettings.cfg -y -inplace -F {} \;
    find . -type f -name "*.pas" -exec dos2unix {} \;
    find . -type f -name "*.DCU" | xargs rm -f;
    find . -type f -name "*.dcu" | xargs rm -f;
    find . -type f -name "*.~*" | xargs rm -f;
    find . -type f -name "*.jcf.pas" | xargs rm -f 
    find . -type d -name "backup" | xargs rm -rf      
    find . -type d -name "__history" | xargs rm -rf      
    find . -type d -name "__recovery" | xargs rm -rf      
    rm -rf "./lib"
    rm -rf "./Win32"
    rm -rf "./Win64"
fi

if $LAZBUILD $PROJECT; then
  if [ $1 = "test" ]; then
    ./ASTBuilder
  fi
fi
