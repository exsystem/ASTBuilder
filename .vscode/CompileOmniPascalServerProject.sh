#!/bin/bash

LAZBUILD="/Applications/Lazarus/lazbuild"
PROJECT="/Users/exsystem/DelphiProjects/MyFormatter/MyFormatter.lpi"

# Modify .lpr file in order to avoid nothing-to-do-bug (http://lists.lazarus.freepascal.org/pipermail/lazarus/2016-February/097554.html)
# echo. >> "/Users/exsystem/DelphiProjects/MyFormatter/MyFormatter.lpr"

if [ $1 = "clean" ] || [ $1 == "test" ]; then
    find "/Users/exsystem/DelphiProjects/MyFormatter" -type f -name "*.pas" | xargs /Users/exsystem/DelphiProjects/jcf/JCF -config=./.vscode/jcfsettings.cfg -y -F 
    find "/Users/exsystem/DelphiProjects/MyFormatter" -type d -name "backup" | xargs rm -rf      
    find "/Users/exsystem/DelphiProjects/MyFormatter" -type d -name "__history" | xargs rm -rf      
    rm -rf "/Users/exsystem/DelphiProjects/MyFormatter/lib"
    rm -rf "/Users/exsystem/DelphiProjects/MyFormatter/Win32"
fi

if $LAZBUILD $PROJECT; then
  if [ $1 = "test" ]; then
    "/Users/exsystem/DelphiProjects/MyFormatter/MyFormatter" 
  fi
fi
