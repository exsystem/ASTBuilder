" Debug script for vim syntax plugin
"
" To use: source this file after opening a .pas file

function! DebugAST() abort
  echo "=== Debug AST ==="
  
  " Get prefix
  let l:buf_dir = expand('%:p:h')
  if !empty(l:buf_dir)
    let l:candidate = l:buf_dir . '/pascal_ast'
    if filereadable(l:candidate . '.xt')
      let s:prefix = l:candidate
    endif
  endif
  
  if !exists('s:prefix')
    let l:ast_dir = '/Users/exsystem/DelphiProjects/XDE/ASTBuilder'
    if filereadable(l:ast_dir . '/pascal_ast.xt')
      let s:prefix = l:ast_dir . '/pascal_ast'
    endif
  endif
  
  if !exists('s:prefix')
    let s:prefix = '/tmp/pascal_ast_1/pascal_ast'
  endif
  
  echo "Prefix: " . s:prefix
  echo "Files exist:"
  echo "  .xt: " . (filereadable(s:prefix . '.xt') ? 'YES' : 'NO')
  echo "  .xs: " . (filereadable(s:prefix . '.xs') ? 'YES' : 'NO')
  echo "  .xtr: " . (filereadable(s:prefix . '.xtr') ? 'YES' : 'NO')
  
  " Check if nodes are being read
  let l:nodes = s:ReadNodes(s:prefix . '.xt')
  echo "Nodes read: " . len(l:nodes)
  
  let l:term_rules = s:ReadCStringFile(s:prefix . '.xtr')
  echo "Term rules read: " . len(l:term_rules)
  
  let l:xs_code = s:ReadCodeString(s:prefix . '.xs')
  echo "XS code length: " . len(l:xs_code)
  
  " Get buffer
  let l:buffer_lines = getline(1, '$')
  call map(l:buffer_lines, 'substitute(v:val, "\r$", "", "")')
  let l:buffer_code = join(l:buffer_lines, "\n") . "\n"
  echo "Buffer code length: " . len(l:buffer_code)
  
  " Get terminals
  let l:terms = []
  for n in l:nodes
    if n.rule == 0
      call add(l:terms, n)
    endif
  endfor
  echo "Terms found: " . len(l:terms)
  
  call sort(l:terms, {a,b -> a.offset - b.offset})
  
  " Extract first 5 terms
  let l:term_data = []
  for i in range(min([5, len(l:terms)]))
    let t = l:terms[i]
    if t.token >= len(l:term_rules) | continue | endif
    let name = l:term_rules[t.token]
    
    let txt = ""
    if i + 1 < len(l:terms)
      let next_offset = l:terms[i+1].offset
      if next_offset > t.offset
        let txt = strpart(l:xs_code, t.offset, next_offset - t.offset)
      endif
    else
      let txt = strpart(l:xs_code, t.offset)
    endif
    
    if len(txt) > 0
      call add(l:term_data, {'name': name, 'text': txt})
    endif
  endfor
  
  echo "Term data: " . len(l:term_data)
  for item in l:term_data
    echo "  " . item.name . ": " . item.text
  endfor
  
endfunction
