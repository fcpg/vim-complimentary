
let s:plugdir = expand('<sfile>:p:h')

" Build signature cache {{{2
function! s:buildCache(exestr)
  let lines = systemlist(a:exestr)
  let json  = join(lines, "\n")
  let obj   = json_decode(json)
  let cache = {}
  for entry in obj
    let name = substitute(entry['word'], '()\?$', '', '')
    if has_key(cache, name)
      let cache[name] = add(cache[name], entry)
    else
      let cache[name] = [entry]
    endif
  endfor
  return [cache, lines]
endfun

function! BuildFunctionCache()
  let exestr = printf('gawk -f "%s" "%s"', s:plugdir."/build_func_json.awk",
        \ $VIMRUNTIME.'/doc/eval.txt')
  let [cache, lines] = s:buildCache(exestr)
  call writefile(lines, s:plugdir."/funccache.json", "b")
  let g:ovm_func_cache = cache
endfun


" Get builtin Vim function signatures {{{2
function! GetFuncInfo(...)
  if !exists('g:ovm_func_cache')
    call BuildFunctionCache()
  endif
  let name = substitute(a:1, '()\?', '', '')
  return get(g:ovm_func_cache, name, [{'word': a:1, 'kind': 'f'}])
endfun


" Build command cache {{{2
function! BuildCommandCache()
  let exestr = printf('gawk -f "%s" "%s"', s:plugdir."/build_cmd_json.awk",
        \ $VIMRUNTIME.'/doc/index.txt')
  let [cache, lines] = s:buildCache(exestr)
  call writefile(lines, s:plugdir."/cmdcache.json", "b")
  let g:ovm_cmd_cache = cache
endfun


" Get builtin Vim function signatures {{{2
function! GetCommandInfo(...)
  if !exists('g:ovm_cmd_cache')
    call BuildCommandCache()
  endif
  let name = substitute(a:1, '()\?', '', '')
  return get(g:ovm_cmd_cache, name, [{'word': a:1}])
endfun


" Build internal variables cache {{{2
function! BuildVarCache()
  let exestr = printf('gawk -f "%s" "%s"', s:plugdir."/build_var_json.awk",
        \ $VIMRUNTIME.'/doc/eval.txt')
  let [cache, lines] = s:buildCache(exestr)
  call writefile(lines, s:plugdir."/varcache.json", "b")
  let g:ovm_var_cache = cache
endfun


" Get builtin Vim variable {{{2
function! GetVarInfo(...)
  if !exists('g:ovm_var_cache')
    call BuildVarCache()
  endif
  return get(g:ovm_var_cache, a:1, [{'word': a:1, 'kind': 'v'}])
endfun


function! CompleteOmnivimore(findstart, base)
  let line = getline('.')
  if a:findstart
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\k\|:'
      let start -= 1
    endwhile
    if start > 0 && line[start - 1] =~ '+\|&\|:'
      let start -= 1
    endif
    return start
  else
    let delpfx = 0
    if strpart(a:base,0,1) == '*'
      let word = strpart(a:base,1)
      let type = 'function'
    elseif strpart(a:base,0,1) == '+'
      let word = strpart(a:base,1)
      let type = 'option'
    elseif strpart(a:base,0,1) == ':'
      let word = strpart(a:base,1)
      let type = 'command'
    else
      let word = a:base
      let type = 'expression'
    endif
    let res = []
    if type == 'expression'
      if line =~ '^\s*\(\K\k*\)\?$'
        let type = 'command'
      elseif line =~ '^\s*se\%(t\?\|tl\%[ocal]\|tg\%[lobal]\)\s\+$'
        let type = 'option'
      endif
    endif
    let comp = getcompletion(word, type)
    for c in comp
      if c =~ '()\?$' || type == 'function'
        let finfos = GetFuncInfo(c)
        for finfo in finfos
          call add(res, finfo)
        endfor
      elseif c =~ '^v:' || type == 'option'
        let vinfos = GetVarInfo(c)
        for vinfo in vinfos
          call add(res, vinfo)
        endfor
      elseif type == 'command'
        let cinfos = GetCommandInfo(c)
        for cinfo in cinfos
          call add(res, cinfo)
        endfor
      else
        call add(res, c)
      endif
    endfor
    return res
  endif
endfun

