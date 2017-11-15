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

let s:cpty_cache_dir = get(g:, 'cpty_cache_dir', s:plugdir)

let s:cpty_use_default_cache = get(g:, 'cpty_use_default_cache', 0)
let s:cpty_use_file_cache    = get(g:, 'cpty_use_file_cache', 1)
let s:cpty_sigil             = get(g:, 'cpty_sigil', 1)
let s:cpty_autocmd           = get(g:, 'cpty_autocmd', 1)

let s:cachefile = {
      \ 'func': s:cpty_cache_dir."/funccache.json",
      \ 'cmd':  s:cpty_cache_dir."/cmdcache.json",
      \ 'var':  s:cpty_cache_dir."/varcache.json",
      \}

let s:defcachefile = {
      \ 'func': s:plugdir."/def_funccache.json",
      \ 'cmd':  s:plugdir."/def_cmdcache.json",
      \ 'var':  s:plugdir."/def_varcache.json",
      \}


"----------------
" Functions {{{1
"----------------

" s:Obj2Cache() {{{2
" Convert an obj from doc parsing into a cache dict
function! s:Obj2Cache(obj)
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
  let exestr = printf('gawk -f "%s" "%s"', s:funcscript,
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
  let exestr = printf('gawk -f "%s" "%s"', s:cmdscript,
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
  let exestr = printf('gawk -f "%s" "%s"', s:varscript,
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


" CompleteCpty() {{{2
" Main completion function
function! CompleteCpty(findstart, base) abort
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
    if s:cpty_sigil && strpart(a:base,0,1) == '*'
      let word = strpart(a:base,1)
      let type = 'function'
    elseif s:cpty_sigil && strpart(a:base,0,1) == '+'
      let word = strpart(a:base,1)
      let type = 'option'
    elseif s:cpty_sigil && strpart(a:base,0,1) == ':'
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
        let cinfos = GetCmdInfo(c)
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


"---------------
" Autocmds {{{1
"---------------

if s:cpty_autocmd && exists('+completefunc')
  augroup Complimentary
    au!
    autocmd Filetype vim
          \ setl omnifunc=CompleteCpty
  augroup END
endif


let &cpo = s:save_cpo

" vim: et sw=2 ts=2 ft=vim:
