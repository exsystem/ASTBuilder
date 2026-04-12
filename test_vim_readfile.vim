" Test how readfile handles line endings

let l:lines = readfile('/Users/exsystem/DelphiProjects/XDE/ASTBuilder/Test/vim.pas')

echo "Number of lines: " . len(l:lines)
if !empty(l:lines)
  echo "First line length: " . len(l:lines[0])
  echo "First line (raw bytes):"
  let l:first_line = l:lines[0]
  for i in range(min([20, len(l:first_line)]))
    echo "  [" . i . "]: " . char2nr(l:first_line[i])
  endfor
endif
