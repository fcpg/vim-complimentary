
let s:plugdir = expand('<sfile>:p:h')

" Build signature cache {{{2
function! BuildSignatureCache()
  let exestr = 
    \ 'awk ''/\*\S+\*\s*$/{p=0;} /\*functions\*\s*$/{p=1;} p==1&&/[a-z \t]/'' '.
    \   $VIMRUNTIME.'/doc/eval.txt'
  let lines = systemlist(exestr)
  let cache = {}
  let cont  = 0
  let l     = ''
  for line in lines
    if cont == 1
      let l = l . line
      let cont = 0
    else
      let l = line
    endif
    let mlist = matchlist(l, 
          \ '^\(\(\K\k\+\)([^)]*)\)'.
          \ '\%('.
          \   '\s\+\(\S\+\%(\s\+or\s\+\S\+\)\?\)'.
          \   '\s*\(.*\)'.
          \ '\)\?$'
          \)
    if len(mlist) > 0
      let [sig, name, ret, desc] = mlist[1:4]
      if ret == ''
        if cont == 1
          let cont = 0
        else
          let cont = 1
        endif
        continue
      endif
      let d = {'word': name.((sig =~ '()$') ? '()' : '('),
            \  'kind': 'f',
            \  'info': sig.' '.ret,
            \  'menu': desc,
            \}
      if has_key(cache, name)
        let cache[name] = add(cache[name], d)
      else
        let cache[name] = [d]
      endif
    endif
  endfor
  let g:ovm_func_cache = cache
endfun


" Get builtin Vim function signatures {{{2
function! GetBuiltinFuncInfo(...)
  if !exists('g:ovm_func_cache')
    call BuildSignatureCache()
  endif
  return get(g:ovm_func_cache, a:1, [{'word': a:1, 'kind': 'f'}])
endfun


" Build internal variables cache {{{2
function! BuildInternalVarCache()
  let exestr = join([
    \ 'gawk -v RS=''\n[^\n]*[\t ]+[*][^\t ]+[*][\t ]*\n'' -F ''\n''',
    \   '''BEGIN {print "[";}',
    \   'oldrt~/\n^v:/ {',
    \     'k=gensub("([^\t ]+).*","\\1",1,oldrt);',
    \     'print "{\"word\": \"" k "\",";',
    \     'print "\"kind\": \"v\",";',
    \     'print "\"info\": \"";',
    \     'print $0;',
    \     'print "\"},";',
    \     'oldrt=RT; next;',
    \   '} ',
    \   '$1~/^v:/ {',
    \     'k=gensub("^(v:[^\t ]+).*","\\1",1,$1);',
    \     'print "{\"word\": \"" k "\",";',
    \     'print "\"kind\": \"v\",";',
    \     'print "\"info\": \"";',
    \     'sub("^v:[^\t ]+[\t ]+","",$1);',
    \     'for(i=1;i<=NF;i++) print gensub("^<?[\t ]*(.*)", "\\1",1,$i);',
    \     'print "\"},";',
    \   '} ',
    \   '{oldrt=RT;}',
    \   'END {print "]";}'' ',
    \   $VIMRUNTIME.'/doc/eval.txt',
    \], ' ')

  let lines = systemlist(exestr)
  let cache = {}
  let d = {}
  echo join(lines, "\n")
  return
  for line in lines
    let mlist = matchlist(line, '^===\(v:\k\+\)===')
    if len(mlist) > 0
      if !empty(d)
        if has_key(cache, name)
          let cache[name] = add(cache[name], d)
        else
          let cache[name] = [d]
        endif
      endif
      let name = mlist[1]
      let d = {'word': name,
            \  'kind': 'v',
            \  'info': "",
            \  'menu': "",
            \}
    else
      if !strlen(d['menu'])
        d['menu'] = line
      endif
      d['info'] = d['info'].'\n'.line
    endif
  endfor
  let g:ovm_vimvar_cache = cache
endfun


" Get builtin Vim variable {{{2
function! GetVimVarInfo(...)
  if !exists('g:ovm_vimvar_cache')
    call BuildInternalVarCache()
  endif
  return get(g:ovm_vimvar_cache, a:1, [{'word': a:1, 'kind': 'v'}])
endfun


function! CompleteOmnivimore(findstart, base)
  if a:findstart
    let line  = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\k\|:'
      let start -= 1
    endwhile
    return start
  else
    let res = []
    let comp = getcompletion(a:base, 'expression')
    for c in comp
      if c =~ '()\?$'
        let name   = substitute(c, '()\?', '', '')
        let finfos = GetBuiltinFuncInfo(name)
        for finfo in finfos
          call add(res, finfo)
        endfor
      elseif c =~ '^v:'
        let vinfos = GetVimVarInfo(c)
        for vinfo in vinfos
          call add(res, vinfo)
        endfor
      else
        call add(res, c)
      endif
    endfor
    return res
  endif
endfun

