" complimentary.vim - better completion for Vim builtins
" Author: fcpg

if exists("g:loaded_complimentary") || &cp
  finish
endif
let g:loaded_complimentary = 1

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

let s:plugdir    = expand('<sfile>:p:h')
let s:funcscript = s:plugdir."/build_func_json.awk"
let s:cmdscript  = s:plugdir."/build_cmd_json.awk"
let s:varscript  = s:plugdir."/build_var_json.awk"
let s:optscript  = s:plugdir."/build_opt_json.awk"
let s:soptscript = s:plugdir."/build_shortopt_json.awk"

let s:cpty_cache_dir = get(g:, 'cpty_cache_dir', s:plugdir)

let s:cpty_use_default_cache = get(g:, 'cpty_use_default_cache', 0)
let s:cpty_use_file_cache    = get(g:, 'cpty_use_file_cache', 1)
let s:cpty_sigil             = get(g:, 'cpty_sigil', 1)
let s:cpty_autocmd           = get(g:, 'cpty_autocmd', 1)
let s:cpty_awk_cmd           = get(g:, 'cpty_awk_cmd', 'gawk -f')

let s:cachefile = {
      \ 'func': s:cpty_cache_dir."/funccache.json",
      \ 'cmd':  s:cpty_cache_dir."/cmdcache.json",
      \ 'var':  s:cpty_cache_dir."/varcache.json",
      \ 'opt':  s:cpty_cache_dir."/optcache.json",
      \ 'sopt': s:cpty_cache_dir."/soptcache.json",
      \}

let s:defcachefile = {
      \ 'func': s:plugdir."/def_funccache.json",
      \ 'cmd':  s:plugdir."/def_cmdcache.json",
      \ 'var':  s:plugdir."/def_varcache.json",
      \ 'opt':  s:plugdir."/def_optcache.json",
      \ 'sopt': s:plugdir."/def_soptcache.json",
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


" BuildFuncCache() {{{2
" Build signature cache
function! BuildFuncCache() abort
  let exestr = printf('%s "%s" "%s"',
        \ s:cpty_awk_cmd,
        \ s:funcscript,
        \ $VIMRUNTIME.'/doc/eval.txt')
  let g:cpty_func_cache = <Sid>BuildCache(exestr, 'func')
endfun


" GetFuncInfo() {{{2
" Get built-in vim function signatures
" Arg: pfx  the prefix to complete
function! GetFuncInfo(pfx) abort
  if !exists('g:cpty_func_cache')
    call BuildFuncCache()
  endif
  let name = substitute(a:pfx, '()\?', '', '')
  return get(g:cpty_func_cache, name, [{'word': a:pfx, 'kind': 'f'}])
endfun


" BuildCmdCache() {{{2
" Build command cache
function! BuildCmdCache() abort
  let exestr = printf('%s "%s" "%s"',
        \ s:cpty_awk_cmd,
        \ s:cmdscript,
        \ $VIMRUNTIME.'/doc/index.txt')
  let g:cpty_cmd_cache = <Sid>BuildCache(exestr, 'cmd')
endfun


" GetCmdInfo() {{{2
" Get built-in vim function signatures
" Arg: pfx  the prefix to complete
function! GetCmdInfo(pfx) abort
  if !exists('g:cpty_cmd_cache')
    call BuildCmdCache()
  endif
  let name = substitute(a:pfx, '()\?', '', '')
  return get(g:cpty_cmd_cache, name, [{'word': a:pfx}])
endfun


" BuildVarCache() {{{2
" Build internal variables cache
function! BuildVarCache() abort
  let exestr = printf('%s "%s" "%s"',
        \ s:cpty_awk_cmd,
        \ s:varscript,
        \ $VIMRUNTIME.'/doc/eval.txt')
  let g:cpty_var_cache = <Sid>BuildCache(exestr, 'var')
endfun


" GetVarInfo() {{{2
" Get builtin vim variable
" Arg: pfx  the prefix to complete
function! GetVarInfo(pfx) abort
  if !exists('g:cpty_var_cache')
    call BuildVarCache()
  endif
  return get(g:cpty_var_cache, a:pfx, [{'word': a:pfx, 'kind': 'v'}])
endfun


" BuildOptCache() {{{2
" Build options cache
function! BuildOptCache() abort
  let exestr = printf('%s "%s" "%s"',
        \ s:cpty_awk_cmd,
        \ s:optscript,
        \ $VIMRUNTIME.'/doc/quickref.txt')
  let g:cpty_opt_cache = <Sid>BuildCache(exestr, 'opt')
endfun


" GetOptInfo() {{{2
" Get builtin vim optiable
" Arg: pfx  the prefix to complete
function! GetOptInfo(pfx) abort
  if !exists('g:cpty_opt_cache')
    call BuildOptCache()
  endif
  return get(g:cpty_opt_cache, a:pfx, [{'word': a:pfx, 'kind': 'v'}])
endfun


" BuildShortoptCache() {{{2
" Build short options cache
function! BuildShortoptCache() abort
  let exestr = printf('%s "%s" "%s"',
        \ s:cpty_awk_cmd,
        \ s:soptscript,
        \ $VIMRUNTIME.'/doc/quickref.txt')
  let g:cpty_shortopt_cache = <Sid>BuildCache(exestr, 'sopt')
endfun

" CompleteCpty() {{{2
" Main completion function
function! CompleteCpty(findstart, base) abort
  let line = getline('.')
  if a:findstart
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\k\|:'
      let start -= 1
    endwhile
    if start > 0 && line[start - 1] =~ '+\|&\|*'
      let start -= 1
    endif
    return start
  else
    if s:cpty_sigil && a:base[0] == '*'
      let word = strpart(a:base,1)
      let type = 'function'
    elseif s:cpty_sigil && a:base[0] == '+'
      let word = strpart(a:base,1)
      let type = 'option'
    elseif s:cpty_sigil && a:base[0] == ':'
      let word = strpart(a:base,1)
      let type = 'command'
    elseif a:base[0] == '&'
      let word = strpart(a:base,1)
      let type = 'option'
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
        call extend(res, GetFuncInfo(c))
      elseif c =~ '^v:'
        call extend(res, GetVarInfo(c))
      elseif type == 'option'
        let r = GetOptInfo(c)
        if a:base[0] == '&'
          " prepend the & to results
          let r = deepcopy(r)
          call map(r, 'extend(v:val, {"word":"&".v:val["word"],'
                \ . '"abbr":v:val["word"]})')
        endif
        call extend(res, r)
      elseif type == 'command'
        call extend(res, GetCmdInfo(c))
      else
        call add(res, c)
      endif
    endfor
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
function! CompleteOpt(arg, line, pos) abort
  if !exists('g:cpty_shortopt_cache')
    call BuildShortoptCache()
  endif
  let a = stridx('*+', a:arg[0]) !=-1 ? strpart(a:arg,1) : a:arg
  let pfx = a:arg[0]
  let sfx = ''
  if a[-1:] == '*'
    let sfx = a[-1:]
    let a = a[0:-2]
  endif
  let res = {}
  for [k, v] in items(g:cpty_shortopt_cache)
    let w = pfx=='+' ? v : k
    if w =~ (pfx=='*'?'':'^').a
      let res[w] = 1
      if sfx=='*'
        let res[v] = 1
      endif
    endif
  endfor
  return keys(res)
endfun


"---------------
" Autocmds {{{1
"---------------

if s:cpty_autocmd && exists('+omnifunc')
  augroup Complimentary
    au!
    autocmd Filetype vim
          \ setl omnifunc=CompleteCpty
  augroup END
endif


"---------------
" Commands {{{1
"---------------

command! -nargs=+ -bar -complete=customlist,CompleteOpt Set
      \ set <args>

let &cpo = s:save_cpo

" vim: et sw=2 ts=2 ft=vim:
