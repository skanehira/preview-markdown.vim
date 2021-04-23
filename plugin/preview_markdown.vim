" preview_markdown
" Author: skanehira
" License: MIT

if exists('g:loaded_preview_markdown')
  finish
endif
let g:loaded_preview_markdown = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=? -complete=customlist,preview_markdown#complete PreviewMarkdown call preview_markdown#preview(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
