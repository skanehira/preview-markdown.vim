" preview_markdown
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:preview_buf_nr = -1

function! s:echo_err(msg) abort
  echohl ErrorMsg
  echom 'preview-markdown.vim: ' . a:msg
  echohl None
endfunction

function! s:remove_tmp_on_nvim(tmp, id, exit_code, type) abort
  call delete(a:tmp)
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

    let opt = {
      \ 'on_exit': function('s:remove_tmp_on_nvim', [tmp])
      \ }

    let s:preview_buf_nr = termopen(cmd, opt)
  else
    let opt = {
          \ 'in_io': 'file',
          \ 'in_name': tmp,
          \ 'hidden': 1,
          \ 'curwin': 1,
          \ 'term_finish': 'open',
          \ 'term_kill': 'kill',
          \ 'term_name': 'PREVIEW',
          \ 'term_opencmd': is_vert ? 'vnew|b %d' : 'new|b %d',
          \ }

    if bufexists(s:preview_buf_nr)
      let winid = bufwinid(s:preview_buf_nr)
      if winid is# -1
        if is_vert
          execute 'vnew'
        else
          execute 'new'
        endif
      else
        call win_gotoid(winid)
      endif
    else
      if is_vert
        execute 'vnew'
      else
        execute 'new'
      endif
    endif

    let jobid = term_getjob(bufnr())
    if jobid isnot# v:null
      call job_stop(jobid)
      let c = 0
      while job_status(jobid) is# 'run'
        if c > 5
          call s:echo_err('stop job is timeout')
          return
        endif
        sleep 1m
        let c += 1
      endwhile
      redraw
    endif

    let s:preview_buf_nr = term_start(parser, opt)
    call delete(tmp)
  endif
endfunction

augroup AutoUpdatePreviewMarkdown
  au!
  autocmd BufWritePre * if &ft is# 'markdown' | call s:auto_preview() | endif

  function! s:auto_preview() abort
    if get(g:, 'preview_markdown_auto_update', 0) |
      " if preview buffer showing in window
      if bufwinid(s:preview_buf_nr) isnot# -1
        call preview_markdown#preview()
      endif
    endif
  endfunction
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
