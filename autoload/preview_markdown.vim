" preview_markdown
" Author: skanehira
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

let s:preview_buf_nr = -1
let s:preview_job_id = -1

function! s:echo_err(msg) abort
  echohl ErrorMsg
  echom 'preview-markdown.vim: ' . a:msg
  echohl None
endfunction

function! s:remove_tmp_on_nvim(tmp, id, exit_code, type) abort
  call delete(a:tmp)
endfunction

function! s:remove_tmp(tmp, channel, msg) abort
  call delete(a:tmp)
endfunction

function! s:stop_job() abort
  if has('nvim')
    let s:jobid = s:preview_job_id
    if ((s:jobid isnot# v:null) && (s:jobid !=# 'no process'))
      call jobstop(s:jobid)
      if bufexists(s:preview_buf_nr)
          execute "bw! " . s:preview_buf_nr
      endif
    endif
  else
    let s:jobid = term_getjob(bufnr('%'))
    if ((s:jobid isnot# v:null) && (s:jobid !=# 'no process'))
      call job_stop(s:jobid)
      let c = 0
      while job_status(s:jobid) is# 'run'
        if c > 5
          call s:echo_err('stop job is timeout')
          return
        endif
        sleep 1m
        let c += 1
      endwhile
      redraw
    endif
  endif
endfunction

let s:args = ['left', 'right', 'top', 'bottom','tab']
let s:arg_to_excmd = {
      \ 'left': 'leftabove',
      \ 'right': 'rightbelow',
      \ 'top': 'topleft',
      \ 'bottom': 'botright',
      \ 'tab': 'tabnew',
      \ }

function! preview_markdown#complete(arg, cmd, pos) abort
  if a:arg is# ''
    return s:args
  endif
  return filter(copy(s:args), printf('v:val =~# "^%s"', a:arg))
endfunction

function! s:to_excmd(args) abort
  let excmd = 'vnew'
  if len(a:args) is 0
    return excmd
  endif

  let arg = a:args[0]

  let open = s:arg_to_excmd[arg]

  if arg is# 'right' || arg is# 'left'
    let excmd = printf('%s vnew', open)
  elseif arg is# 'tab'
    let excmd = printf('%s tabnew', open)
  else
    let excmd = printf('%s new', open)
  endif

  return excmd
endfunction

function! preview_markdown#preview(...) abort
  if wordcount().bytes is 0
    call s:echo_err('current buffer is empty')
    return
  endif

  let tmp = tempname() . '.md'
  call writefile(getline(1, "$"), tmp)

  let parser = get(g:, 'preview_markdown_parser', 'mdr')
  let bin = split(parser,' ')[0]

  if !executable(bin)
    call s:echo_err(printf('%s not found, please install %s', bin, bin))
    return
  endif

  if !has('terminal') && !has('nvim')
    call s:echo_err('this version doesn''t support terminal')
    return
  endif

  let opencmd = s:to_excmd(a:000)
  let cmd = printf("%s %s", parser, tmp)

  if has('nvim')
    let opt = {
      \ 'on_exit': function('s:remove_tmp_on_nvim', [tmp])
      \ }

    if bufexists(s:preview_buf_nr)
      let winid = bufwinid(s:preview_buf_nr)
      if winid isnot# -1
        call win_gotoid(winid)
      endif
    endif

    call s:stop_job()
    execute opencmd
    let s:preview_job_id = termopen(cmd, opt)
    let s:preview_buf_nr = bufnr('$')
  else
    let opt = {
          \ 'hidden': 1,
          \ 'curwin': 1,
          \ 'term_finish': 'open',
          \ 'term_kill': 'kill',
          \ 'term_name': 'PREVIEW',
          \ 'term_opencmd': printf('%s|b %%d', opencmd),
          \ 'exit_cb': function('s:remove_tmp', [tmp]),
          \ }

    if bufexists(s:preview_buf_nr)
      let winid = bufwinid(s:preview_buf_nr)
      if winid is# -1
        execute opencmd
      else
        call win_gotoid(winid)
      endif
    else
        execute opencmd
    endif

    call s:stop_job()
    let s:preview_buf_nr = term_start(cmd, opt)
    exe printf('tnoremap <buffer> <silent> q %s:bw! \| call <SID>stop_job()<CR>', &termwinkey isnot# '' ? &termwinkey : '<C-w>')
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
