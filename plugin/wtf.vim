" Vim global plugin for setting your &fo straight
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.1
" Description:	Interactively set your &formatoptions
" Last Change:	2014-02-01
" License:	Vim License (see :help license)
" Location:	plugin/fo-builder.vim
" Website:	https://github.com/dahu/vim-wtf
"
" See wtf.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help wtf

" autowrap:  comments, text, except-long, orphan-control
" comments:  when-pressing-enter-in-insert-mode, when-opening-newlines
" reformat:  automatic, autocomments, comments
" reindent:  number/bullet-lists, hanging
" multibyte: join-with-spaces, join-with-keep-together, join-packed
"
" Vim's default is: ['comments,text','','comments','','']

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

" load guard
" uncomment after plugin development.
" XXX The conditions are only as examples of how to use them. Change them as
" needed. XXX
"if exists("g:loaded_vim-wtf")
"      \ || v:version < 700
"      \ || v:version == 703 && !has('patch338')
"      \ || &compatible
"  let &cpo = s:save_cpo
"  finish
"endif
"let g:loaded_vim-wtf = 1

" Options: {{{1
if !exists('g:vim_wtf_some_plugin_option')
  let g:vim_wtf_some_plugin_option = 0
endif

" Private Functions: {{{1
function! s:MyScriptLocalFunction()
  echom "change MyScriptLocalFunction"
endfunction

" Public Interface: {{{1

function! SubOpt(opt, subopt)
  return matchstr(a:opt, '\C' . a:subopt)
endfunction

function! WTF_OptionBuilder(...)
  let fo = {}
  let fo.opt = {}
  let fo.known_opts = 'tcroqwan2vblmMB1'
  let fo.opts  = ['text',     'comments', 'insert',    'open'
        \,        'comments', '',         'automatic', 'list'
        \,        'hanging',  '',         '',          'long'
        \,        'space',    'keep',     'pack',      'orphan']
  let fo.group_opts = {
        \  'autowrap'  : 'tcl1'
        \, 'comments'  : 'ro'
        \, 'reformat'  : 'aq'
        \, 'reindent'  : 'n2'
        \, 'multibyte' : 'mMB'
        \}
  let fo.help_text = {
   \  'autowrap'  : "(text), (comments), except-(long), (orphan)-control"
   \, 'comments'  : "when-pressing-enter-in-(insert)-mode, when-(open)ing-newlines"
   \, 'reformat'  : "all text (automatic)ally | (autocomments) | (comments) with gq"
   \, 'reindent'  : "number/bullet-(list)s | (hang)ing from second line of paragraph"
   \, 'multibyte' : "join-with-(space)s | join-with-(keep)-together | join-(pack)ed"
   \}

  let fo.dependent_opts = {
        \  't' : 'textwidth'
        \, 'c' : 'textwidth'
        \, 'l' : 'textwidth'
        \, '1' : 'textwidth'
        \, 'n' : 'autoindent'
        \, '2' : 'autoindent'
        \ }
  let fo.added_c_for_auto_comments = 0

  func fo.name(opt) dict
    return self.opts[stridx(self.known_opts, a:opt)]
  endfunc

  func fo.set(...) dict
    if a:0
      let from_fo = a:1
    else
      let from_fo = &formatoptions
    endif
    for o in split(self.known_opts, '\zs')
      let self.opt['_' . o] = SubOpt(from_fo, o)
    endfor
    " WTF doesn't respect old vi settings
    for o in split('wvb', '\zs')
      call self.remove(o)
    endfor
  endfunc

  func fo.remove(subopt) dict
    if has_key(self.opt, '_' . a:subopt)
      let self.opt['_' . a:subopt] = ''
    endif
  endfunc

  func fo.add(subopt) dict
    if has_key(self.opt, '_' . a:subopt)
      let self.opt['_' . a:subopt] = a:subopt
    endif
  endfunc

  func fo.to_option() dict
    let opt_fo = ''
    for o in sort(keys(self.opt))
      let opt_fo .= self.opt[o]
    endfor
    return opt_fo
  endfunc

  func fo.has(subopt) dict
    if has_key(self.opt, '_' . a:subopt)
      return self.opt['_' . a:subopt] != ''
    endif
    return 0
  endfunc

  func fo.apply() dict
    exe 'set fo=' . self.to_option()
  endfunc

  " Builder Interface - separated into logical formatoption groups

  " choices: comments, text, except-long, orphan-control, none|off
  func fo.autowrap(choice) dict
    let choice = a:choice
    let opt = ''
    call self.remove('t')
    call self.remove('c')
    call self.remove('l')
    call self.remove('1')
    if choice =~? '\<t\%[ext]'
      call self.add('t')
    endif
    if choice =~? '\<c\%[omment]'
      call self.add('c')
    endif
    if choice =~? '\<l\%[ong]'
      call self.add('l')
      if ! (self.has('t') || self.has('c'))
        call self.add('t')
      endif
    endif
    if choice =~? '\<o\%[rphan]'
      call self.add('1')
      if ! (self.has('t') || self.has('c'))
        call self.add('t')
      endif
    endif
  endfunc

  " choices: when-pressing-enter-in-insert-mode, when-opening-newlines
  func fo.comments(choice) dict
    let choice = a:choice
    let opt = ''
    call self.remove('r')
    call self.remove('o')
    if choice =~? '\<i\%[nsert]'
      call self.add('r')
    endif
    if choice =~? '\<o\%[pen]'
      call self.add('o')
    endif
  endfunc

  " choices: automatic|[manual], comments
  func fo.reformat(choice) dict
    let choice = a:choice
    let opt = ''
    call self.remove('a')
    call self.remove('q')
    if self.added_c_for_auto_comments
      call self.remove('c')
      let self.added_c_for_auto_comments = 0
    endif
    if choice =~? '\<a\%[utomatic]'
      call self.add('a')
      if choice =~? '\<autoc\%[omment]'
        if ! self.has('c')
          call self.add('c')
          let self.added_c_for_auto_comments = 1
        endif
      endif
    endif
    if choice =~? '\<c\%[omment]'
      call self.add('q')
    endif
  endfunc

  " choices: numbers-and-bullets, hanging
  func fo.reindent(choice) dict
    let choice = a:choice
    let opt = ''
    call self.remove('n')
    call self.remove('2')
    if choice =~? '\<n\%[umber]\|\<b\%[ullet]\|\<l\%[ist]'
      call self.add('n')
      call self.remove('2')
    endif
    if choice =~? '\<h\%[ang]'
      call self.remove('n')
      call self.add('2')
    endif
  endfunc

  " choices: join-with-spaces, join-with-keep-together, join-packed
  func fo.multibyte(choice) dict
    let choice = a:choice
    let opt = ''
    call self.remove('m')
    call self.remove('B')
    call self.remove('M')
    if choice =~? '\<k\%[eep]'
      call self.add('m')
      call self.add('B')
      call self.remove('M')
    endif
    if choice =~? '\<p\%[ack]'
      call self.add('m')
      call self.remove('B')
      call self.add('M')
    endif
    if choice =~? '\<s\%[pace]'
      call self.add('m')
      call self.remove('B')
      call self.remove('M')
    endif
  endfunc

  " options are dynamically marked up as (+enabled+) or (-disabled-)
  " which will render better with syntax highlighting
  func fo.help(group, opts_set) dict
    let s = self.help_text[a:group]
    for o in split(a:opts_set, '\s*,\s*')
      let s = substitute(s, '(' . o . ')', '(+' . o . '+)', '')
    endfor
    return substitute(s, '(\(\w\+\))', '(-\1-)', 'g')
  endfunc

  func fo.show(group) dict
    let group_opts = []
    for o in split(self.group_opts[a:group], '\zs')
      if self.has(o)
        call add(group_opts, self.name(o))
      endif
    endfor
    return join(group_opts, ',')
  endfunc

  func fo.wtf(option, ...) dict
    if a:0
      let option_set = extend([a:option], a:000)
    else
      let option_set = a:option
    endif
    let os = 0
    for f in ['autowrap', 'comments', 'reformat', 'reindent', 'multibyte']
      exe 'call self.' . f . '(' .  string(option_set[os]) . ')'
      let os += 1
    endfor
    call self.apply()
  endfunc

  func fo.vim_default() dict
    call self.wtf('comments,text', '', 'comments', '', '')
  endfunc

  call call(fo.set, a:000, fo)
  return fo
endfunction

function! WTF(fo)
  call s:WTF_win(WTF_OptionBuilder(a:fo))
endfunction

function! s:WTF_win(fo_obj)
  let FO = a:fo_obj

  new wtf-window
  setlocal noro buftype=nofile fdm=marker

  " Insert help and each formatoption group with choices
  " TODO: get the real bnum and printf it three digits wide; real bname
  let bnum = 0
  let bname = '~/foo.txt'
  call append('$',   '" Showing &formatoption details for buffer ' . bnum . '.            {{{')
  call append('$', '"   #' . bname . '#')
  call append('$', '" Each pair of lines show a &formatoption group')
  call append('$', '"   and the available choices it can take.')
  call append('$', '"   * Combinable choices separated by comma (,)')
  call append('$', '"   * Exclusive choices separated by pipe   (|)')
  call append('$', '" Edit each group line manually and press <CR> to update')
  call append('$', '"   the   set fo=...   line at the bottom of this window.')
  call append('$', '"   Yank this setting to use it in your desired buffer.')
  call append('$', '" Type :help wtf-groups for a more detailed explanation. }}}')
  call append('$', '')

  for g in ["autowrap", "comments", "reformat", "reindent", "multibyte"]
    let title = printf("%9s", g)
    let group_opts_set = FO.show(g)
    call append('$', title . ' : ' . group_opts_set)
    call append('$', repeat(' ', 12) . FO.help(g, group_opts_set))
  endfor

  call append('$', '')
  call append('$', '" set fo=' . FO.to_option())

  " delete first line which is an artifact of using append('$')
  1
  delete
  " the formatoptions groups start on line:
  12

  " reset 'modified', so that ":q" can be used to close the window
  setlocal nomodified ft=wtf-window

  " Install autocommands to enable mappings in option-window
  noremap  <silent> <buffer> <CR>    <C-\><C-N>:call CR()<CR>
  inoremap <silent> <buffer> <CR>    <Esc>:call s:CR()<CR>
  noremap  <silent> <buffer> <Space> :call s:Space()<CR>

  " Make the buffer be deleted when the window is closed.
  setlocal buftype=nofile bufhidden=delete noswapfile

  augroup wtfwin
    au! BufUnload,BufHidden wtf-window nested
          \ call s:unload() | delfun s:unload
  augroup END

  function! s:unload()
    delfun s:CR
    au! wtfwin
  endfunction

endfunction

" Maps: {{{1
nnoremap <Plug>wtf1 :call <SID>MyScriptLocalFunction()<CR>
nnoremap <Plug>wtf2 :call MyPublicFunction()<CR>

if !hasmapto('<Plug>PublicPlugName1')
  nmap <unique><silent> <leader>p1 <Plug>wtf1
endif

if !hasmapto('<Plug>PublicPlugName2')
  nmap <unique><silent> <leader>p2 <Plug>wtf2
endif

" Commands: {{{1
command! -nargs=0 -bar WTF call WTF(&fo)

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
