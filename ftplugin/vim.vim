" complimentary.vim - better completion for Vim builtins
" Author: fcpg

if exists('+omnifunc')
  setl ofu=complimentary#CompleteCpty
endif

let b:undo_ftplugin = "setl ofu<"
