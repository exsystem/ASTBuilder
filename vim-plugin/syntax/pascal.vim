" =========================================================
" Pascal AST Syntax Highlighter (FIXED - Positional parsing)
" =========================================================
" if exists("b:current_syntax")
"   finish
" endif

syntax case ignore

" Set global variables only if they don't already exist
if !exists('g:ast_builder') || type(g:ast_builder) == v:t_list
    let g:ast_builder = expand('~/.vim/astbuilder/ASTBuilder')
    if type(g:ast_builder) == v:t_list
        let g:ast_builder = empty(g:ast_builder) ? "" : g:ast_builder[0]
    endif
endif

if !exists('g:grammar') || type(g:grammar) == v:t_list
    let g:grammar = expand('~/.vim/astbuilder/pascal.xg')
    if type(g:grammar) == v:t_list
        let g:grammar = empty(g:grammar) ? "" : g:grammar[0]
    endif
endif

if !exists('g:ast_prefix') || type(g:ast_prefix) == v:t_list
    let g:ast_prefix = '/tmp/pascal_ast_1/pascal_'
endif

if !exists('g:plugin') || type(g:plugin) == v:t_list
  " 1. Detect the platform
  let s:is_windows = has('win32') || has('win64')
  let s:is_mac = has('macunix')

  " 2. Set the correct extension
  if s:is_windows
    let s:ext = '.dll'
  elseif s:is_mac
    let s:ext = '.dylib'
  else
    let s:ext = '.so'
  endif

  " 3. Build the path using expand() to handle '~'
  " Note: Vim's expand() handles forward slashes internally on Windows
  let s:path = expand('~/.vim/astbuilder/libpascal' . s:ext)
  if type(s:path) == v:t_list
    let s:path = empty(s:path) ? "" : s:path[0]
  endif

  " 4. Final normalization for Windows paths if needed
  let g:plugin = simplify(s:path)
endif

let s:prefix = g:ast_prefix
let s:debug_log = []

function! s:BlobToStr(blob) abort
    if empty(a:blob) | return "" | endif
    " blob2str(blob) in Vim 8.1+ converts a blob to a string directly
    " It handles multi-byte characters correctly as it just takes the raw bytes.
    let s = blob2str(a:blob)
    " Replace null bytes with \x01 if they exist (though blob2str might stop at null)
    " But for our purpose of matching against buffer_code (also read as blob), it should be consistent.
    return s
endfunction

function! s:ToHexPattern(input) abort
    let l:result = ""
    let l:i = 0
    let l:data = a:input
    
    " If input is a list, flatten it
    while type(l:data) == v:t_list
      let l:data = empty(l:data) ? "" : l:data[0]
    endwhile

    if type(l:data) == v:t_blob
        let l:len = len(l:data)
        while l:i < l:len
            let l:nr = l:data[l:i]
            let l:byte_str = nr2char(l:nr)
            if l:nr < 32 || l:nr > 126 || l:byte_str =~ '[\\/ \[\]^$.*~]'
                let l:result .= printf('\x%02x', l:nr)
            else
                let l:result .= l:byte_str
            endif
            let l:i += 1
        endwhile
    else
        " It's a string (or something else converted to string)
        let l:s = l:data
        if type(l:s) != v:t_string
            let l:s = string(l:s)
            let l:s = substitute(l:s, "^'\\|'$", '', 'g')
        endif
        
        let l:len = strlen(l:s)
        while l:i < l:len
            let l:byte_str = strpart(l:s, l:i, 1)
            let l:nr = char2nr(l:byte_str)
            if l:nr < 32 || l:nr > 126 || l:byte_str =~ '[\\/ \[\]^$.*~]'
                let l:result .= printf('\x%02x', l:nr)
            else
                let l:result .= l:byte_str
            endif
            let l:i += 1
        endwhile
    endif
    return l:result
endfunction

" =========================
" READ C-STRINGS (.xnr / .xtr)
" =========================
function! s:ReadCStringFile(path) abort
    if !filereadable(a:path)
      return []
    endif

    let blob = readblob(a:path)
    if type(blob) == v:t_list | let blob = list2blob(blob) | endif
    if type(blob) != v:t_blob | let blob = 0z | endif

    let out = []
    let start = 0
    let i = 0
    let blob_len = len(blob)
    
    while i < blob_len
      if blob[i] == 0
        if i > start
          let part = blob[start : i-1]
          call add(out, s:BlobToStr(part))
        else
          call add(out, "")
        endif
        let start = i + 1
      endif
      let i += 1
    endwhile
    
    if start < blob_len
      let part = blob[start : blob_len-1]
      call add(out, s:BlobToStr(part))
    elseif start == blob_len && blob_len > 0 && blob[blob_len-1] == 0
      " Ends with null, nothing to add
    endif

    return out
endfunction

" =========================
" READ CODE BLOB (.xs)
" =========================
function! s:ReadCodeBlob(path) abort
  if !filereadable(a:path)
    return 0z
  endif

  let blob = readblob(a:path)
  if type(blob) == v:t_list | let blob = list2blob(blob) | endif
  if type(blob) != v:t_blob | let blob = 0z | endif

  " Find null terminator if any
  let null_idx = index(blob, 0)
  if null_idx == 0
    return 0z
  elseif null_idx > 0
    let blob = blob[0 : null_idx - 1]
  endif
  
  return blob
endfunction

" =========================
" READ AST NODES (.xt) - C++ EXACT PORT (Little-Endian)
" =========================
function! s:ReadNodes(path) abort
  if !filereadable(a:path)
    return []
  endif

  let data = readblob(a:path)
  if type(data) == v:t_list | let data = list2blob(data) | endif
  if type(data) != v:t_blob | let data = 0z | endif

  let nodes = []

  let i = 0
  while i + 40 <= len(data)
    " Parse 5 x 8-byte fields in little-endian format (same as Python struct.unpack('<Q'*5, ...))
    " Offset 0: parent
    " Offset 8: rule (0 = terminal marker)
    " Offset 16: token (terminal ID)
    " Offset 24: start (end position or secondary offset)
    " Offset 32: offset (The TRUE start position in .xs)

    " NO OP to check line 197
    let debug_i = i
    let parent = 0
    let rule   = 0
    let token  = 0
    let start  = 0
    let offset = 0

    for j in range(8)
      " Little-endian: least significant byte first
      " Ensure we use integer multiplication to avoid float if possible
      let b0 = data[i + 0 + j]
      let b1 = data[i + 8 + j]
      let b2 = data[i + 16 + j]
      let b3 = data[i + 24 + j]
      let b4 = data[i + 32 + j]
      
      let mult = float2nr(pow(256, j))
      let parent += b0 * mult
      let rule   += b1 * mult
      let token  += b2 * mult
      let start  += b3 * mult
      let offset += b4 * mult
    endfor

    let n_parent = 0 + parent
    let n_rule = 0 + rule
    let n_token = 0 + token
    let n_start = 0 + start
    let n_offset = 0 + offset
    
    let node = {'parent': n_parent, 'rule': n_rule, 'token': n_token, 'start': n_start, 'offset': n_offset}
    call add(nodes, node)

    let i = i + 40
  endwhile

  return nodes
endfunction

" =========================
" MAIN AST PROCESSOR
" =========================
function! s:BuildAST(...) abort
  " If a path is passed as argument, use it as prefix
  if a:0 > 0
    let l:prefix = a:1
  else
    let l:prefix = g:ast_prefix
  endif
  
  while type(l:prefix) == v:t_list
    let l:prefix = empty(l:prefix) ? "" : l:prefix[0]
  endwhile
  
  let l:buf_path = expand('%:p')
  if type(l:buf_path) == v:t_list
    let l:buf_path = empty(l:buf_path) ? "" : l:buf_path[0]
  endif

  let l:xt_path = l:prefix . "ast.xt"
  let l:xtr_path = l:prefix . "ast.xtr"
  let l:xs_path = l:prefix . "ast.xs"

  if !filereadable(l:xt_path) || !filereadable(l:xtr_path) || !filereadable(l:xs_path) || !filereadable(l:buf_path)
    return
  endif

  let l:term_rules = s:ReadCStringFile(l:xtr_path)
  let l:xs_blob = readblob(l:xs_path)
  let l:buffer_blob = readblob(l:buf_path)

  " Calculate line offsets
  let l:line_offsets = [0]
  let l:i = 0
  let l:buffer_len = len(l:buffer_blob)
  while l:i < l:buffer_len
    if l:buffer_blob[l:i] == 10 " \n
      call add(l:line_offsets, l:i + 1)
    endif
    let l:i += 1
  endwhile

  let l:nodes = s:ReadNodes(l:xt_path)
  let l:terms = []
  for l:n in l:nodes
    if l:n.rule == 0
      call add(l:terms, l:n)
    endif
  endfor

  call sort(l:terms, {a, b -> a.offset - b.offset})

  let l:term_data = []
  let l:num_terms = len(l:terms)
  let l:xs_blob_len = len(l:xs_blob)

  for l:i in range(l:num_terms)
    let l:t = l:terms[l:i]
    let l:token_id = l:t.token
    if l:token_id >= len(l:term_rules)
      continue
    endif
    let l:name = l:term_rules[l:token_id]

    let l:start_in_xs = l:t.offset
    if l:i + 1 < l:num_terms
      let l:end_in_xs = l:terms[l:i+1].offset
    else
      let l:end_in_xs = l:xs_blob_len
    endif

    if l:end_in_xs > l:start_in_xs
      let l:txt_blob = l:xs_blob[l:start_in_xs : l:end_in_xs - 1]
      call add(l:term_data, {'name': l:name, 'text_blob': l:txt_blob, 'start_pos': l:t.start})
    endif
  endfor

  let l:KEYWORDS = {'PROGRAM':1, 'UNIT':1, 'INTERFACE':1, 'IMPLEMENTATION':1, 'USES':1, 'TYPE':1, 'RECORD':1, 'VAR':1, 'CONST':1, 'BEGIN':1, 'END':1, 'PROCEDURE':1, 'FUNCTION':1, 'IF':1, 'THEN':1, 'ELSE':1, 'FOR':1, 'WHILE':1, 'REPEAT':1, 'UNTIL':1, 'DO':1, 'WITH':1, 'GOTO':1, 'LABEL':1, 'ARRAY':1, 'OF':1, 'FILE':1, 'SET':1, 'STRING':1, 'AND':1, 'OR':1, 'NOT':1, 'XOR':1, 'DIV':1, 'MOD':1, 'SHL':1, 'SHR':1, 'IN':1, 'AS':1, 'IS':1, 'NIL':1, 'TO':1, 'DOWNTO':1, 'EXIT':1, 'RESULT':1, 'READLN':1, 'WRITELN':1, 'READ':1, 'WRITE':1, 'BYTE':1, 'INTEGER':1, 'BOOLEAN':1, 'CHAR':1, 'WORD':1, 'LONGINT':1, 'DOUBLE':1, 'SINGLE':1, 'EXTENDED':1, 'PCHAR':1, 'POINTER':1, 'TSIZE':1, 'PSIZE':1, 'REAL':1}

  let l:buffer_pos = 0

  syntax case ignore

  for l:item in l:term_data
    let l:name = l:item.name
    while type(l:name) == v:t_list
      let l:name = empty(l:name) ? "" : l:name[0]
    endwhile
    if type(l:name) != v:t_string
      let l:name = string(l:name)
      let l:name = substitute(l:name, "^'\\|'$", '', 'g')
    endif
    let l:txt_blob = l:item.text_blob
    
    let l:txt_len = len(l:txt_blob)
    if l:txt_len == 0 | continue | endif
    let l:first_byte = l:txt_blob[0]

    " Find the blob in the buffer
    let l:found_pos = -1
    let l:search_start = l:buffer_pos
    
    " Check if it's exactly at current position first
    if l:search_start + l:txt_len <= l:buffer_len
      let l:slice = l:buffer_blob[l:search_start : l:search_start + l:txt_len - 1]
      if l:slice ==# l:txt_blob
        let l:found_pos = l:search_start
      endif
    endif

    if l:found_pos == -1
      let l:found_pos = index(l:buffer_blob, l:first_byte, l:search_start)
      while l:found_pos != -1
        let l:slice = l:buffer_blob[l:found_pos : l:found_pos + l:txt_len - 1]
        if l:slice ==# l:txt_blob
          break
        endif
        let l:found_pos = index(l:buffer_blob, l:first_byte, l:found_pos + 1)
      endwhile
    endif

    if l:found_pos == -1
      " Try from 0 if not found from current position
      let l:found_pos = index(l:buffer_blob, l:first_byte, 0)
      while l:found_pos != -1
        let l:slice = l:buffer_blob[l:found_pos : l:found_pos + l:txt_len - 1]
        if l:slice ==# l:txt_blob
          break
        endif
        let l:found_pos = index(l:buffer_blob, l:first_byte, l:found_pos + 1)
      endwhile
    endif

    if l:found_pos == -1
      continue
    endif

    let l:actual_len = len(l:txt_blob)
    let l:buffer_pos = l:found_pos + l:actual_len

    " Calculate line/col
    " Simple bisect_right equivalent
    let l:low = 0
    let l:high = len(l:line_offsets)
    while l:low < l:high
      let l:mid = (l:low + l:high) / 2
      if l:line_offsets[l:mid] <= l:found_pos
        let l:low = l:mid + 1
      else
        let l:high = l:mid
      endif
    endwhile
    let l:line_idx = l:low - 1
    let l:lnum = l:line_idx + 1
    let l:cnum = l:found_pos - l:line_offsets[l:line_idx] + 1

    let l:group = ""
    if l:name =~# '^\(START_HEREDOC\|@HEREDOC_END\|HEREDOC_TEXT\)$'
      let l:group = "pascalHeredoc"
    elseif l:name is# 'STRING_LITERAL'
      let l:group = "pascalString"
    elseif l:name is# 'NUM_REAL'
      let l:group = "pascalFloat"
    elseif l:name is# 'NUM_INT'
      let l:group = "pascalNumber"
    elseif has_key(l:KEYWORDS, l:name)
      let l:group = "pascalKeyword"
    elseif l:name =~# '^\(IDENTIFIER\|ID\|IDENT\|NAME\|TEXT\|STRING\)$'
      let l:group = "pascalIdentifier"
    elseif l:name is# 'STRING_LITERAL_TYPE'
      let l:group = "pascalType"
    elseif l:name =~# '^\(DIRECTIVE\|COMPILER_DIRECTIVE\|COMMENT_1\|COMMENT_2\)$'
      let l:group = "pascalComment"
    endif

    if !empty(l:group)
      let l:pattern = s:ToHexPattern(l:txt_blob)
      if !empty(l:pattern)
        let l:cmd = printf('syntax match %s /\%%%dl\%%%dc\V%s/', l:group, l:lnum, l:cnum, l:pattern)
        execute l:cmd
      endif
    endif
  endfor

  hi! link pascalKeyword Keyword
  hi! link pascalIdentifier Identifier
  hi! link pascalType Type
  hi! link pascalNumber Number
  hi! link pascalFloat Float
  hi! link pascalString String
  hi! link pascalHeredoc String 
  hi! link pascalDirective PreProc
  hi! link pascalComment Comment
endfunction

function! PascalSyntaxHighlight() abort
  call s:GenerateAST()
  call s:BuildAST()
endfunction

augroup PascalAST
  autocmd!
  " Run BuildAST when the buffer is read/post or filetype is set
  " Use BufReadPost to ensure file content is loaded first
  autocmd BufReadPost,BufNewFile *.pas call PascalSyntaxHighlight()
augroup END

" Command to manually trigger AST building
command! -nargs=? BuildAST call s:BuildAST(<f-args>)

" Helper command to generate AST files for current buffer
command! GenerateAST call s:GenerateAST()

command! PascalSyntaxHighlight call PascalSyntaxHighlight()

function! s:GenerateAST() abort
  let l:buf_name = expand('%:p')
  if type(l:buf_name) == v:t_list
    let l:buf_name = empty(l:buf_name) ? "" : l:buf_name[0]
  endif
  if empty(l:buf_name)
    echo "No buffer loaded"
    return
  endif
  echo "Generating AST for: " . l:buf_name
  let l:cmd = string(g:ast_builder) . ' ' . string(g:grammar) . ' ' . string(l:buf_name) . ' ' . string(g:ast_prefix) . ' ' . string(g:plugin)
  echo "Running: " . l:cmd
  let l:result = system(l:cmd)
  echo l:result
endfunction

let b:current_syntax = "pascal"
