#!/bin/bash

LAZBUILD="/Applications/Lazarus/lazbuild"
PROJECT="/Users/exsystem/DelphiProject/MyFormatter/MyFormatter.lpi"

# Modify .lpr file in order to avoid nothing-to-do-bug (http://lists.lazarus.freepascal.org/pipermail/lazarus/2016-February/097554.html)
# echo. >> "/Users/exsystem/DelphiProject/MyFormatter/MyFormatter.lpr"

if $LAZBUILD $PROJECT; then

  if [ $1 = "test" ]; then
    "/Users/exsystem/DelphiProject/MyFormatter/MyFormatter" 
  fi
fi
