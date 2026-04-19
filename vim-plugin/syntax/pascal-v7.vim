" =========================================================
" Pascal AST Syntax Highlighter (Modified for PPC MacOS X 10.4)
" =========================================================
if exists("b:current_syntax")
    finish
endif

syntax case ignore

" Set global variables only if they don't already exist
if !exists('g:ast_builder') || type(g:ast_builder) != 1
    let g:ast_builder = expand('~/.vim/astbuilder/ASTBuilder')
    while type(g:ast_builder) == 3
        let g:ast_builder = g:ast_builder[0]
    endwhile
endif

if !exists('g:grammar') || type(g:grammar) != 1
    let g:grammar = expand('~/.vim/astbuilder/pascal.xg')
    while type(g:grammar) == 3
        let g:grammar = g:grammar[0]
    endwhile
endif

if !exists('g:ast_prefix') || type(g:ast_prefix) != 1
    let g:ast_prefix = '/tmp/pascal_ast_1/pascal_'
endif

if !exists('g:plugin') || type(g:plugin) != 1
    " Platform detection simplified for compatibility
    let s:is_mac = has('macunix')
    
    " Set appropriate extension based on platform (Mac uses .dylib)
    if s:is_mac
        let s:ext = '.dylib'
    else
        let s:ext = '.so'
    endif

    let s:path = expand('~/.vim/astbuilder/libpascal' . s:ext)
    while type(s:path) == 3
        let s:path = empty(s:path) ? "" : s:path[0]
    endwhile

    " Normalize path for compatibility
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

    let lines = readfile(a:path)
    let out = []
    for line in lines
        let trimmed_line = substitute(line, '\n\+', '', 'g')
        call add(out, trimmed_line)
    endfor

    return out
endfunction

" =========================
" READ CODE BLOB (.xs) - Read as string
" =========================
function! s:ReadCodeBlob(path) abort
    if !filereadable(a:path)
        return ""
    endif

    let content = join(readfile(a:path), "")
    return content
endfunction

" =========================
" READ AST NODES (.xt) - Simplified for compatibility
" =========================
function! s:ReadNodes(path) abort
    if !filereadable(a:path)
        return []
    endif

    let data = join(readfile(a:path), "")
    let nodes = []

    " Simplified node parsing (example only; actual implementation may vary)
    let lines = split(data, '\n')
    for line in lines
        let parts = split(line, '\t')
        if len(parts) >= 5
            let node = {'parent': parts[0], 'rule': parts[1], 'token': parts[2],
                      \ 'start': parts[3], 'offset': parts[4]}
            call add(nodes, node)
        endif
    endfor

    return nodes
endfunction

" =========================
" MAIN AST PROCESSOR (Simplified)
" =========================
function! s:BuildAST(...) abort
    let l:prefix = a:0 > 0 ? a:1 : g:ast_prefix
    while type(l:prefix) == 3
        let l:prefix = empty(l:prefix) ? "" : l:prefix[0]
    endwhile

    let l:buf_path = expand('%:p')
    while type(l:buf_path) == 3
        let l:buf_path = empty(l:buf_path) ? "" : l:buf_path[0]
    endwhile

    let l:xt_path = l:prefix . "ast.xt"
    let l:xtr_path = l:prefix . "ast.xtr"
    let l:xs_path = l:prefix . "ast.xs"

    if !filereadable(l:xt_path) || !filereadable(l:xtr_path) || !filereadable(l:xs_path)
        return
    endif

    let l:term_rules = s:ReadCStringFile(l:xtr_path)
    let l:xs_content = s:ReadCodeBlob(l:xs_path)
    let l:buffer_content = join(readfile(expand('%')), "")

    " Calculate line offsets (simplified)
    let l:line_offsets = [0]
    let i = 0
    while i < len(l:buffer_content)
        if l:buffer_content[i] == "\n"
            call add(l:line_offsets, i + 1)
        endif
        let i += 1
    endwhile

    let l:nodes = s:ReadNodes(l:xt_path)
    let l:terms = filter(l:nodes, 'v:val.rule == "0"')

    for node in l:terms
        if has_key(node, 'token') && !empty(node.token) && node.token < len(l:term_rules)
            let token_id = str2nr(node.token)
            let name = l:term_rules[token_id]

            " Simplified processing logic
            echo "Processing token: " . name
        endif
    endfor
endfunction

" =========================
" HIGHLIGHTING SETUP (Simplified)
" =========================
hi! link pascalKeyword Keyword
hi! link pascalIdentifier Identifier
hi! link pascalType Type
hi! link pascalNumber Number
hi! link pascalFloat Float
hi! link pascalString String
hi! link pascalHeredoc String
hi! link pascalDirective PreProc
hi! link pascalComment Comment

augroup PascalAST
    autocmd!
    " Trigger on file read and buffer creation
    autocmd BufReadPost,BufNewFile *.pas call s:BuildAST()
augroup END

command! -nargs=? BuildAST call s:BuildAST(<f-args>)
command! GenerateAST echo "GenerateAST placeholder"
command! PascalSyntaxHighlight call s:BuildAST()

let b:current_syntax = "pascal"
