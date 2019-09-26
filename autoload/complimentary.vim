" complimentary.vim - better completion for Vim builtins
" Author: fcpg

let s:save_cpo = &cpo
set cpo&vim


"------------
" Debug {{{1
"------------

let g:cpty_debug = 1
if 0
append
  " comment out all dbg calls
  :g,\c^\s*call <Sid>Dbg(,s/call/"call/
  " uncomment
  :g,\c^\s*"call <Sid>Dbg(,s/"call/call/
.
endif


"--------------
" Options {{{1
"--------------

let s:datadir    = expand('<sfile>:p:h:h').'/data'
let s:funcscript = s:datadir."/build_func_json.awk"
let s:cmdscript  = s:datadir."/build_cmd_json.awk"
let s:varscript  = s:datadir."/build_var_json.awk"
let s:optscript  = s:datadir."/build_opt_json.awk"
let s:soptscript = s:datadir."/build_shortopt_json.awk"

let s:cpty_cache_dir = get(g:, 'cpty_cache_dir', s:datadir)

let s:cpty_use_default_cache = get(g:, 'cpty_use_default_cache', 1)
let s:cpty_use_file_cache    = get(g:, 'cpty_use_file_cache', 1)
let s:cpty_awk_cmd           = get(g:, 'cpty_awk_cmd', 'gawk -f')

let s:cachefile = {
      \ 'func': s:cpty_cache_dir."/funccache.json",
      \ 'cmd':  s:cpty_cache_dir."/cmdcache.json",
      \ 'var':  s:cpty_cache_dir."/varcache.json",
      \ 'opt':  s:cpty_cache_dir."/optcache.json",
      \ 'sopt': s:cpty_cache_dir."/soptcache.json",
      \}

let s:defcachefile = {
      \ 'func': s:datadir."/def_funccache.json",
      \ 'cmd':  s:datadir."/def_cmdcache.json",
      \ 'var':  s:datadir."/def_varcache.json",
      \ 'opt':  s:datadir."/def_optcache.json",
      \ 'sopt': s:datadir."/def_soptcache.json",
      \}


"----------------
" Functions {{{1
"----------------

" s:Obj2Cache() {{{2
" Convert an obj from doc parsing into a cache dict
function! s:Obj2Cache(obj)
  if type(a:obj) == type({})
    return a:obj
  endif
  let cache = {}
  for entry in a:obj
    let name = substitute(entry['word'], '()\?$', '', '')
    if has_key(cache, name)
      let cache[name] = add(cache[name], entry)
    else
      let cache[name] = [entry]
    endif
  endfor
  return cache
endfun


" s:BuildCache() {{{2
" Generic cache building func
" Arg: exestr  the string fed to system() to build the cache
" Arg: type    type of cache Cf. s:cachefile keys
function! s:BuildCache(exestr, type) abort
  let cachefile = get(s:cachefile, a:type, '')
  if s:cpty_use_default_cache
    "call <Sid>Dbg('Reading info from default cache file', a:type)
    let lines = readfile(s:defcachefile[a:type])
  elseif s:cpty_use_file_cache && filereadable(cachefile)
    "call <Sid>Dbg('Reading info from cache file', a:type)
    let lines = readfile(cachefile)
  else
    "call <Sid>Dbg('Generating completion info', a:type)
    let lines = systemlist(a:exestr)
    if s:cpty_use_file_cache && cachefile != ''
      "call <Sid>Dbg('Writing info into cache file', a:type)
      silent! call writefile(lines, cachefile, "b")
    endif
  endif
  let json = join(lines, "\n")
  let obj  = json_decode(json)
  return <Sid>Obj2Cache(obj)
endfun


" s:BuildFuncCache() {{{2
" Build signature cache
function! s:BuildFuncCache() abort
  let exestr = printf('%s "%s" "%s"',
        \ s:cpty_awk_cmd,
        \ s:funcscript,
        \ $VIMRUNTIME.'/doc/eval.txt')
  let g:cpty_func_cache = <Sid>BuildCache(exestr, 'func')
endfun


" s:GetFuncInfo() {{{2
" Get built-in vim function signatures
" Arg: pfx  the prefix to complete
function! s:GetFuncInfo(pfx) abort
  if !exists('g:cpty_func_cache')
    call <Sid>BuildFuncCache()
  endif
  let name = substitute(a:pfx, '()\?', '', '')
  return get(g:cpty_func_cache, name, [{'word': a:pfx, 'kind': 'f'}])
endfun


" s:BuildCmdCache() {{{2
" Build command cache
function! s:BuildCmdCache() abort
  let exestr = printf('%s "%s" "%s"',
        \ s:cpty_awk_cmd,
        \ s:cmdscript,
        \ $VIMRUNTIME.'/doc/index.txt')
  let g:cpty_cmd_cache = <Sid>BuildCache(exestr, 'cmd')
endfun


" s:GetCmdInfo() {{{2
" Get built-in command signatures
" Arg: pfx  the prefix to complete
function! s:GetCmdInfo(pfx) abort
  if !exists('g:cpty_cmd_cache')
    call <Sid>BuildCmdCache()
  endif
  let name = substitute(a:pfx, '()\?', '', '')
  return get(g:cpty_cmd_cache, name, [{'word': a:pfx}])
endfun


" s:BuildVarCache() {{{2
" Build internal variables cache
function! s:BuildVarCache() abort
  let exestr = printf('%s "%s" "%s"',
        \ s:cpty_awk_cmd,
        \ s:varscript,
        \ $VIMRUNTIME.'/doc/eval.txt')
  let g:cpty_var_cache = <Sid>BuildCache(exestr, 'var')
endfun


" s:GetVarInfo() {{{2
" Get builtin vim variable
" Arg: pfx  the prefix to complete
function! s:GetVarInfo(pfx) abort
  if !exists('g:cpty_var_cache')
    call <Sid>BuildVarCache()
  endif
  return get(g:cpty_var_cache, a:pfx, [{'word': a:pfx, 'kind': 'v'}])
endfun


" s:BuildOptCache() {{{2
" Build options cache
function! s:BuildOptCache() abort
  let exestr = printf('%s "%s" "%s"',
        \ s:cpty_awk_cmd,
        \ s:optscript,
        \ $VIMRUNTIME.'/doc/quickref.txt')
  let g:cpty_opt_cache = <Sid>BuildCache(exestr, 'opt')
endfun


" s:GetOptInfo() {{{2
" Get builtin vim option description
" Arg: pfx  the prefix to complete
function! s:GetOptInfo(pfx) abort
  if !exists('g:cpty_opt_cache')
    call <Sid>BuildOptCache()
  endif
  return get(g:cpty_opt_cache, a:pfx, [{'word': a:pfx, 'kind': 'v'}])
endfun


" s:BuildShortoptCache() {{{2
" Build short options cache
function! s:BuildShortoptCache() abort
  let exestr = printf('%s "%s" "%s"',
        \ s:cpty_awk_cmd,
        \ s:soptscript,
        \ $VIMRUNTIME.'/doc/quickref.txt')
  let g:cpty_shortopt_cache = <Sid>BuildCache(exestr, 'sopt')
endfun

" CompleteCpty() {{{2
" Main completion function
function! complimentary#CompleteCpty(findstart, base) abort
  let line = getline('.')
  if a:findstart
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\k\|:'
      let start -= 1
    endwhile
    if start > 0 && line[start - 1] =~ '+\|&\|*\|#'
      let start -= 1
    endif
    return start
  else
    if get(g:, 'cpty_sigil', 0) && a:base[0] == '*'
      let word = strpart(a:base,1)
      let type = 'function'
    elseif get(g:, 'cpty_sigil', 0) && a:base[0] == '+'
      let word = strpart(a:base,1)
      let type = 'option'
    elseif get(g:, 'cpty_sigil', 0) && a:base[0] == ':'
      let word = strpart(a:base,1)
      let type = 'command'
    elseif get(g:, 'cpty_sigil', 0) && a:base[0] == '#'
      let word = strpart(a:base,1)
      let type = 'event'
    elseif a:base[0] == '&'
      let word = strpart(a:base,1)
      let type = 'option'
    else
      let word = a:base
      let type = 'expression'
    endif
    let res = []
    if type == 'expression'
      if line =~ '\%(^\||\)\s*\(\K\k*\)\?$'
        let type = 'command'
      elseif line =~ '\%(^\||\)\s*se\%(t\?\|tl\%[ocal]\|tg\%[lobal]\)\s\+$'
        let type = 'option'
      elseif line =~ '\%(^\||\)\s*au\%[tocmd]\%(\s\+\S\+\)\?\s\+\%(\S\+,\)\?$'
        let type = 'event'
      endif
    endif
    let comp = getcompletion(word, type)
    for c in comp
      if c =~ '()\?$' || type == 'function'
        call extend(res, <Sid>GetFuncInfo(c))
      elseif c =~ '^v:'
        call extend(res, <Sid>GetVarInfo(c))
      elseif type == 'option'
        let r = <Sid>GetOptInfo(c)
        if a:base[0] == '&'
          " prepend the & to results
          let r = deepcopy(r)
          call map(r, 'extend(v:val, {"word":"&".v:val["word"],'
                \ . '"abbr":v:val["word"]})')
        endif
        call extend(res, r)
      elseif type == 'command'
        call extend(res, <Sid>GetCmdInfo(c))
      else
        call add(res, c)
      endif
    endfor
    " exclude menu info if 'cot contains popup
    if has('patch-8.1.1880')
          \ && &completeopt =~ 'popup'
          \ && !get(g:, 'cpty_always_menu', 0)
      let i = len(res) - 1
      while i>=0
        let e = res[i]
        if has_key(e, 'menu')
          let res[i] = deepcopy(e)
          call remove(res[i], 'menu')
        endif
        let i -= 1
      endwhile
    endif
    return res
  endif
endfun


" s:Dbg {{{2
function! s:Dbg(msg, ...) abort
  if g:cpty_debug
    let m = a:msg
    if a:0
      let m .= " [".join(a:000, "] [")."]"
    endif
    echom m
  endif
endfun


" CompleteOpt {{{2
" Completion func for :Set
function! complimentary#CompleteOpt(arg, line, pos) abort
  if !exists('g:cpty_shortopt_cache')
    call <Sid>BuildShortoptCache()
  endif
  let a = a:arg
  " look for +/* prefix
  let pfx = a[0]
  if stridx('*+', pfx) != -1
    let a = strpart(a,1)
  endif
  " look for % glob
  let glob = 0
  if stridx('%', a[0]) != -1
    let a = strpart(a,1)
    let glob = 1
  endif
  " look for * suffix
  let sfx = ''
  if a[-1:] == '*'
    let sfx = a[-1:]
    let a   = a[0:-2]
  endif
  let res = {}
  for [k, v] in items(g:cpty_shortopt_cache)
    " search in long name
    if pfx != '+'
      if k =~ (glob?'':'^').a
        let res[k] = 1
        if sfx == '*'
          let res[v] = 1
        endif
      endif
    endif
    " search in short name
    if stridx('*+', pfx) != -1
      if v =~ (glob?'':'^').a
        let res[v] = 1
      endif
    endif
  endfor
  return keys(res)
endfun


" RebuildCaches {{{2
" Rebuild the user cached data
function! complimentary#RebuildCaches() abort
  for f in values(s:cachefile)
    call delete(f)
  endfor
  call <Sid>BuildFuncCache()
  call <Sid>BuildCmdCache()
  call <Sid>BuildVarCache()
  call <Sid>BuildOptCache()
  call <Sid>BuildShortoptCache()
endfun


let &cpo = s:save_cpo

" vim: et sw=2 ts=2 ft=vim:
