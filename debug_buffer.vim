" Debug buffer reading issue

function! DebugBuffer() abort
  echo "=== Buffer Debug ==="
  
  let l:buf_path = expand('%:p')
  echo "Buffer path: " . l:buf_path
  echo "File readable: " . (filereadable(l:buf_path) ? 'YES' : 'NO')
  
  if filereadable(l:buf_path)
    let buffer_lines = readfile(l:buf_path, 'b')
    echo "Buffer lines (readfile b): " . len(buffer_lines)
    if !empty(buffer_lines)
      echo "First 5 elements: "
      for i in range(min([5, len(buffer_lines)]))
        echo "  [" . i . "]: " . buffer_lines[i]
      endfor
    endif
    
    let buffer_code = ''
    for char in buffer_lines
      let buffer_code .= nr2char(char)
    endfor
    
    echo "Buffer code length: " . len(buffer_code)
  endif
endfunction
