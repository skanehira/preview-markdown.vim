" preview_markdown
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:preview_buf_name = 'PREVIEW'

function! s:echo_err(msg) abort
  echohl ErrorMsg
  echom 'preview-markdown.vim: ' . a:msg
  echohl None
endfunction

function! preview_markdown#preview() abort
  if wordcount().bytes is 0
    call s:echo_err('current buffer is empty')
    return
  endif

  let tmp = tempname() . '.md'
  call writefile(getline(1, "$"), tmp)

  let parser = get(g:, 'preview_markdown_parser', 'mdr')

  if !executable(parser)
    call s:echo_err(printf('%s not found, please install %s', parser, parser))
    return
  endif

  if !has('terminal') && !has('nvim')
    call s:echo_err('this version doesn''t support terminal')
    return
  endif

  let is_vert = get(g:, 'preview_markdown_vertical', 0)

  if has('nvim')
    if is_vert
      vnew
    else
      new
    endif

    let cmd = printf("%s %s", parser, tmp)

    call termopen(cmd, opt)
  else
    let opt = {
          \ 'in_io': 'file',
          \ 'in_name': tmp,
          \ 'hidden': 1,
          \ 'curwin': 1,
          \ 'term_finish': 'open',
          \ 'term_kill': 'kill',
          \ 'term_name': s:preview_buf_name,
          \ 'term_opencmd': is_vert ? 'vnew|b %d' : 'new|b %d',
          \ }

    if bufexists(s:preview_buf_name)
      let winid = bufwinid(s:preview_buf_name)
      if winid is# -1
        if is_vert
          execute 'vnew | b' s:preview_buf_name
        else
          execute 'new | b' s:preview_buf_name
        endif
      else
        call win_gotoid(winid)
      endif
    else
      if is_vert
        execute 'vnew' s:preview_buf_name
      else
        execute 'new' s:preview_buf_name
      endif
      nnoremap <buffer> <silent> q :bw!<CR>
    endif

    let jobid = term_getjob(bufnr())
    if jobid isnot# v:null
      call job_stop(jobid)
      redraw
    endif

    call term_start(parser, opt)
  endif

  " delete tmp file
  call delete(tmp)
endfunction

augroup AutoPreviewMarkdown
  au!
  autocmd BufWritePre * if &ft is# 'markdown' | call s:auto_preview() | endif

  function! s:auto_preview() abort
    if get(g:, 'preview_markdown_auto', 0) |
      " if preview buffer showing in window
      if bufwinid(s:preview_buf_name) isnot# -1
        call preview_markdown#preview()
      endif
    endif
  endfunction
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
