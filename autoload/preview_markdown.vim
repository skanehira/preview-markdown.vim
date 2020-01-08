" preview_markdown
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

function! s:echo_err(msg) abort
  echohl ErrorMsg
  echom 'preview-markdown.vim: ' .. a:msg
  echohl None
endfunction

function! preview_markdown#preview() abort
  let tmp = tempname()
  call writefile(getline(1, "$"), tmp)

  if !executable('mdr')
    call s:echo_err('not found mdr, please insatll from https://github.com/MichaelMure/mdr')
    return
  endif

  if !has('terminal')
    call s:echo_err('this version doesn''t support terminal')
    return
  endif

  let opt = {
        \ 'in_io': 'file',
        \ 'in_name': tmp,
        \ 'exit_cb': function('s:remove_tmp', [tmp]),
        \ 'vertical': get(g:, 'preview_markdown_vertical', 0),
        \ 'term_finish': 'close',
        \ }

  call term_start('mdr', opt)
endfunction

function! s:remove_tmp(tmp, channel, msg) abort
  call delete(a:tmp)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
