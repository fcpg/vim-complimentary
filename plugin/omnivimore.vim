
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
  let g:ovm_cache = cache
endfun


" Get builtin Vim function signatures {{{2
function! GetBuiltinFuncInfo(...)
  if !exists('g:ovm_cache')
    call BuildSignatureCache()
  endif
  return get(g:ovm_cache, a:1, [{'word': a:1, 'kind': 'f'}])
endfun


function! CompleteOmnivimore(findstart, base)
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\a'
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
      else
        call add(res, c)
      endif
    endfor
    return res
  endif
endfun


