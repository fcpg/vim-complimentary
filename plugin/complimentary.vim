" complimentary.vim - better completion for Vim builtins
" Author: fcpg

if exists("g:loaded_complimentary") || &cp
  finish
endif
let g:loaded_complimentary = 1

let s:save_cpo = &cpo
set cpo&vim


"---------------
" Commands {{{1
"---------------

if !get(g:, 'cpty_no_set_cmd', 0)
  command! -nargs=+ -bar -complete=customlist,complimentary#CompleteOpt Set
        \ set <args>

  command! -nargs=+ -bar -complete=customlist,complimentary#CompleteOpt Setl
        \ setl <args>

  command! -nargs=+ -bar -complete=customlist,complimentary#CompleteOpt Setg
        \ setg <args>
endif

command! -bar ComplimentaryRebuild
      \ call complimentary#RebuildCaches()


let &cpo = s:save_cpo

" vim: et sw=2 ts=2 ft=vim:
