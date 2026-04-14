" =========================================================
" Pascal AST Syntax Highlighter (FIXED - Positional parsing)
" =========================================================
" if exists("b:current_syntax")
"   finish
" endif

syntax case ignore

" Set global variables only if they don't already exist
if !exists('g:ast_builder')
    let g:ast_builder = expand('~/.vim/astbuilder/ASTBuilder')
endif

if !exists('g:grammar')
    let g:grammar = expand('~/.vim/astbuilder/pascal.xg')
endif

if !exists('g:ast_prefix')
    let g:ast_prefix = '/tmp/pascal_ast_1/pascal_'
endif

if !exists('g:plugin')
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

  " 4. Final normalization for Windows paths if needed
  let g:plugin = simplify(s:path)
endif

let s:prefix = g:ast_prefix
let s:debug_log = []

" =========================
" READ C-STRINGS (.xnr / .xtr)
" =========================
function! s:ReadCStringFile(path) abort
    if !filereadable(a:path)
      return []
    endif

    let data = readblob(a:path)
    let out = []
    let str = ""

  for i in range(0, len(data) - 1)
    let b = data[i]

    if b == 0
      " Always add string (even if empty) when we hit a null byte
      call add(out, str)
      let str = ""
    else
      let str .= nr2char(b)
    endif
  endfor

  " Add remaining string if any (before final null or at end)
  if strlen(str) > 0
    call add(out, str)
  endif

  return out
endfunction

" =========================
" READ CODE STRING (.xs)
" =========================
function! s:ReadCodeString(path) abort
  if !filereadable(a:path)
    return ""
  endif

  let data = readblob(a:path)
  let out = ""

  for i in range(0, len(data) - 1)
    if data[i] == 0
      break
    endif
    let out .= nr2char(data[i])
  endfor

  return out
endfunction

" =========================
" READ AST NODES (.xt) - C++ EXACT PORT (Little-Endian)
" =========================
function! s:ReadNodes(path) abort
  if !filereadable(a:path)
    return []
  endif

  let data = readblob(a:path)
  let nodes = []

  let i = 0
  while i + 40 <= len(data)
    " Parse 5 x 8-byte fields in little-endian format (same as Python struct.unpack('<Q'*5, ...))
    " Offset 0: parent
    " Offset 8: rule (0 = terminal marker)
    " Offset 16: token (terminal ID)
    " Offset 24: start (end position or secondary offset)
    " Offset 32: offset (The TRUE start position in .xs)

    let parent = 0
    let rule   = 0
    let token  = 0
    let start  = 0
    let offset = 0

    for j in range(8)
      " Little-endian: least significant byte first
      let parent += data[i + 0 + j] * float2nr(pow(256, j))
      let rule   += data[i + 8 + j] * float2nr(pow(256, j))
      let token  += data[i + 16 + j] * float2nr(pow(256, j))
      let start  += data[i + 24 + j] * float2nr(pow(256, j))
      let offset += data[i + 32 + j] * float2nr(pow(256, j))
    endfor

    call add(nodes, {
          \ 'parent': parent,
          \ 'rule': rule,
          \ 'token': token,
          \ 'start': start,
          \ 'offset': offset
          \ })

    let i += 40
  endwhile

  return nodes
endfunction

" =========================
" MAIN AST PROCESSOR
" =========================
function! s:BuildAST(...) abort
  " If a path is passed as argument, use it as prefix
  if a:0 > 0
    let s:prefix = a:1
  endif
  
  let s:debug_log = ["START s:BuildAST() at " . strftime("%H:%M:%S")]
  let term_rules = s:ReadCStringFile(s:prefix . "ast.xtr")
  let xs_code = s:ReadCodeString(s:prefix . "ast.xs")
  
  " Get original buffer content (preserving line endings)
  let l:buf_path = expand('%:p')
  
  " Read file directly to preserve original line endings
  " readfile() without 'b' flag returns lines with \r\n preserved
  let buffer_lines = readfile(l:buf_path)
  
  " Join lines with \r\n to preserve original format
  let buffer_code = join(buffer_lines, "\r\n") . "\r\n"
  
  " Debug logging
  call add(s:debug_log, "Buffer path: " . l:buf_path)
  call add(s:debug_log, "Buffer lines from readfile: " . len(buffer_lines))
  call add(s:debug_log, "Final buffer_code length: " . len(buffer_code))
  
  " DEBUG: Show sample of buffer
  if len(buffer_code) > 100
    call add(s:debug_log, "Buffer first 50 chars: " . buffer_code[0:49])
    call add(s:debug_log, "Buffer chars 50-100: " . buffer_code[50:99])
  endif
  
  let nodes = s:ReadNodes(s:prefix . "ast.xt")

  call add(s:debug_log, "term_rules length: " . len(term_rules))
  call add(s:debug_log, "nodes length: " . len(nodes))
  call add(s:debug_log, "buffer_code length: " . len(buffer_code))
  call add(s:debug_log, "AST prefix: " . s:prefix)

  if len(nodes) == 0 || len(term_rules) == 0
    call writefile(s:debug_log, "/tmp/ast_syntax_highlighter_debug.log")
    return
  endif

  " Extract terminals using xs file content, with positions from nodes
  " For terminal nodes:
  "   - t.start = start position in original buffer (where token begins)
  "   - t.offset = start position in xs file (for extraction)
  
  let terms = []
  for n in nodes
    if n.rule == 0
      call add(terms, n)
    endif
  endfor
  
  " DEBUG: Check term nodes
  call add(s:debug_log, "Term nodes count: " . len(terms))
  if !empty(terms)
    let first_term = terms[0]
    call add(s:debug_log, "First term node: parent=" . first_term.parent . ", rule=" . first_term.rule . ", token=" . first_term.token . ", start=" . first_term.start . ", offset=" . first_term.offset)
    call add(s:debug_log, "First term name from term_rules[" . first_term.token . "]: '" . (first_term.token < len(term_rules) ? term_rules[first_term.token] : 'OUT_OF_BOUNDS') . "'")
  endif
  
  call sort(terms, {a,b -> a.offset - b.offset})  " Sort by offset in xs file

  let term_data = []
  for i in range(len(terms))
    let t = terms[i]
    if t.token >= len(term_rules) | continue | endif
    let name = term_rules[t.token]
    
    " Extract token text from xs file using offset
    let txt = ""
    if i + 1 < len(terms)
      let next_offset = terms[i+1].offset
      if next_offset > t.offset
        let txt = strpart(xs_code, t.offset, next_offset - t.offset)
      endif
    else
      " Last token: extract to end of xs file
      let txt = strpart(xs_code, t.offset)
    endif
    
    if len(txt) > 0
      call add(term_data, {'name': name, 'text': txt, 'start_pos': t.start})
    endif
  endfor

  " Pre-calculate line offsets in original buffer (count both \n and \r\n)
  let line_offsets = [0]
  let idx = 0
  while 1
    let idx = stridx(buffer_code, "\n", idx)
    if idx == -1 | break | endif
    let idx += 1
    call add(line_offsets, idx)
  endwhile

  " Clear existing groups
  silent! syntax clear pascalKeyword pascalIdentifier pascalType pascalNumber pascalFloat pascalString pascalHeredoc pascalDirective pascalComment

  let in_heredoc_stack = []
  let buffer_pos = 0
  let curr_line_idx = 0

  for i in range(len(term_data))
    let item = term_data[i]
    let name = item.name
    let tok_text = item.text
    let start_pos = item.start_pos  " Start position in original buffer

    " DEBUG: Check name value
    call add(s:debug_log, "Token " . i . ": name='" . name . "', text='" . tok_text . "'")
    
    " Build search pattern from token text (handle special chars)
    " First, escape the text for use as a literal pattern
    let pattern = escape(tok_text, '\/')
    
    " Handle line endings specially:
    " - Token text from xs may contain \r or \n characters
    " - We need to match them in buffer_code which has \r\n line endings
    " - So we replace literal line breaks with optional ones
    
    " First handle \r\n (CRLF) - this should come first
    let search_pattern = substitute(pattern, '\r\n', '\\r\\n\\?', 'g')
    
    " Then handle standalone \r or \n
    let search_pattern = substitute(search_pattern, '\r', '\\r\\?', 'g')
    let search_pattern = substitute(search_pattern, '\n', '\\r?\\n', 'g')
    
    " Also escape tabs for literal matching
    let search_pattern = substitute(search_pattern, '\t', '\\t', 'g')
    
    " Skip patterns that would match empty strings
    if search_pattern == '' || search_pattern == '\r?\n?' || search_pattern == '\r?'
       continue
    endif

    " Search in buffer starting from buffer_pos (using literal matching)
    let found_pos = match(buffer_code, '\c' . search_pattern, buffer_pos)
    
    " If not found from current position, try from beginning
    if found_pos == -1
      " Skip identifiers and comments that might be hard to match
      if name ==# 'ID' || name ==# 'IDENT' || name ==# 'IDENTIFIER' || name ==# 'COMMENT_1' || name ==# 'COMMENT_2'
         continue
      endif
      let found_pos = match(buffer_code, '\c\V' . search_pattern, 0)
      
      if found_pos == -1
        call add(s:debug_log, "MISS pattern: " . search_pattern . " for " . name)
        continue
      endif
    endif

    let actual_len = matchend(buffer_code, '\c\V' . search_pattern, found_pos) - found_pos
    if actual_len <= 0
      continue
    endif
    
    let buffer_pos = found_pos + actual_len

    " Verify the token is at approximately the right position
    " (within a reasonable range to account for whitespace differences)
    let pos_diff = abs(found_pos - start_pos)
    
    " Only accept if position is close enough (within 20 chars tolerance)
    " or if this is the first match and it's reasonably near
    if pos_diff > 20 && start_pos < len(buffer_code)
      " Try to verify by checking if token text exists at start position
      let expected_text = strpart(buffer_code, start_pos, min([actual_len, strlen(tok_text) + 10]))
      if expected_text !~# '\V' . escape(tok_text, '\/')
        call add(s:debug_log, "POS_MISMATCH: found=" . found_pos . ", expected=" . start_pos . ", text=" . tok_text)
        continue
      endif
    endif

    " Calculate line/col from found position
    while curr_line_idx + 1 < len(line_offsets) && line_offsets[curr_line_idx + 1] <= found_pos
      let curr_line_idx += 1
    endwhile
    let lnum = curr_line_idx + 1
    let cnum = found_pos - line_offsets[curr_line_idx] + 1
    let pos_prefix = '\%' . lnum . 'l\%' . cnum . 'c'

    " Use found position for the final pattern
    let actual_text = strpart(buffer_code, found_pos, actual_len)
    let final_pattern = escape(actual_text, '\/')
    let final_pattern = substitute(final_pattern, "\n", '\\n', 'g')
    let final_pattern = substitute(final_pattern, "\r", '\\r', 'g')
    let final_pattern = substitute(final_pattern, "\t", '\\t', 'g')

    let group = ""

    " Token categorization
    if name ==# 'START_HEREDOC'
      call add(in_heredoc_stack, 1)
      let group = "pascalHeredoc"
    elseif name ==# '@HEREDOC_END'
      if !empty(in_heredoc_stack)
        call remove(in_heredoc_stack, -1)
      endif
      let group = "pascalHeredoc"
    elseif name ==# 'HEREDOC_TEXT' || !empty(in_heredoc_stack)
      let group = "pascalHeredoc"
    elseif name ==# 'STRING_LITERAL'
      let group = "pascalString"
    elseif name ==# 'NUM_REAL'
      let group = "pascalFloat"
    elseif name ==# 'NUM_INT'
      let group = "pascalNumber"
    elseif name ==# 'PROGRAM' || name ==# 'UNIT' || name ==# 'INTERFACE' || name ==# 'IMPLEMENTATION' || name ==# 'USES' || name ==# 'TYPE' || name ==# 'RECORD' || name ==# 'VAR' || name ==# 'CONST' || name ==# 'BEGIN' || name ==# 'END' || name ==# 'PROCEDURE' || name ==# 'FUNCTION' || name ==# 'IF' || name ==# 'THEN' || name ==# 'ELSE' || name ==# 'FOR' || name ==# 'WHILE' || name ==# 'REPEAT' || name ==# 'UNTIL' || name ==# 'DO' || name ==# 'WITH' || name ==# 'GOTO' || name ==# 'LABEL' || name ==# 'ARRAY' || name ==# 'OF' || name ==# 'FILE' || name ==# 'SET' || name ==# 'STRING' || name ==# 'AND' || name ==# 'OR' || name ==# 'NOT' || name ==# 'XOR' || name ==# 'DIV' || name ==# 'MOD' || name ==# 'SHL' || name ==# 'SHR' || name ==# 'IN' || name ==# 'AS' || name ==# 'IS' || name ==# 'NIL' || name ==# 'TO' || name ==# 'DOWNTO' || name ==# 'EXIT' || name ==# 'RESULT' || name ==# 'READLN' || name ==# 'WRITELN' || name ==# 'READ' || name ==# 'WRITE' || name ==# 'BYTE' || name ==# 'INTEGER' || name ==# 'BOOLEAN' || name ==# 'CHAR' || name ==# 'WORD' || name ==# 'LONGINT' || name ==# 'DOUBLE' || name ==# 'SINGLE' || name ==# 'EXTENDED' || name ==# 'PCHAR' || name ==# 'POINTER' || name ==# 'TSIZE' || name ==# 'PSIZE' || name ==# 'REAL'
      let group = "pascalKeyword"
    elseif name ==# 'IDENTIFIER' || name ==# 'ID' || name ==# 'IDENT' || name ==# 'NAME' || name ==# 'TEXT' || name ==# 'STRING'
      let group = "pascalIdentifier"
    elseif name ==# 'STRING_LITERAL_TYPE'
      let group = "pascalType"
    elseif name ==# 'DIRECTIVE' || name ==# 'COMPILER_DIRECTIVE'
      let group = "pascalComment"
    elseif name ==# 'COMMENT_1' || name ==# 'COMMENT_2'
      let group = "pascalComment"
    endif

    if group != ""
      let cmd = 'syntax match ' . group . ' /' . pos_prefix . '\V' . final_pattern . '/'
      execute cmd
      call add(s:debug_log, "APPLY: " . cmd)
    endif
  endfor

  hi! link pascalKeyword Keyword
  hi! link pascalIdentifier Identifier
  hi! link pascalType Type
  hi! link pascalNumber Number
  hi! link pascalFloat Float
  hi! link pascalString String
  "hi! link pascalHeredoc String
  " Example for a dark background setup:
  highlight pascalHeredoc ctermbg=242 guibg=#444444 ctermfg=117 guifg=#add8e6
  hi! link pascalDirective PreProc
  hi! link pascalComment Comment

  call add(s:debug_log, "LOOP FINISHED")
  call writefile(s:debug_log, "/tmp/pascal_debug.txt")
endfunction

function! s:PascalSyntaxHighlight() abort
  call s:GenerateAST()
  call s:BuildAST()
endfunction

augroup PascalAST
  autocmd!
  " Run BuildAST when the buffer is read/post or filetype is set
  " Use BufReadPost to ensure file content is loaded first
  autocmd BufReadPost,BufNewFile *.pas call s:PascalSyntaxHighlight()
  " Also try FileType as fallback
  autocmd FileType pascal call s:PascalSyntaxHighlight()
augroup END

" Command to manually trigger AST building
command! -nargs=? BuildAST call s:BuildAST(<f-args>)

" Helper command to generate AST files for current buffer
command! GenerateAST call s:GenerateAST()

command! PascalSyntaxHighlight call s:PascalSyntaxHighlight()

function! s:GenerateAST() abort
  let l:buf_name = expand('%:p')
  if empty(l:buf_name)
    echo "No buffer loaded"
    return
  endif
  echo "Generating AST for: " . l:buf_name
  let l:cmd = g:ast_builder . ' ' . g:grammar . ' ' . l:buf_name . ' ' . g:ast_prefix . ' ' . g:plugin
  echo "Running: " . l:cmd
  let l:result = system(l:cmd)
  echo l:result
endfunction

let b:current_syntax = "pascal"
