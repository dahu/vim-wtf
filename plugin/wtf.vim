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
" reformat:  automatic, autocomments, manual
" reindent:  number/bullet-lists, hanging
" multibyte: join-with-spaces, join-with-keep-together, join-packed
"
" Vim's default is: ['comments,text','','manual','','']

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

" load guard
"if exists("g:loaded_vim-wtf")
"      \ || v:version < 700
"      \ || &compatible
"  let &cpo = s:save_cpo
"  finish
"endif
"let g:loaded_vim-wtf = 1

" Private Functions: {{{1

function! s:SubOpt(opt, subopt)
  return matchstr(a:opt, '\C' . a:subopt)
endfunction

function! s:ToggleOpt(opts, opt)
  let opts = a:opts
  let opt = a:opt
  if opts =~? opt
    let opts = substitute(opts, '\<' . opt . '\>', '', 'g')
  else
    let opts = opt . ',' . opts
  endif
  return opts
endfunction

" Public Interface: {{{1

function! WTF(...)
  let fo = {}
  let fo.opt = {}
  let fo.known_opts = 'tcroqwan2vblmMB1'
  let fo.opts  = ['text',     'comments', 'insert',    'open'
        \,        'manual',   '',         'automatic', 'list'
        \,        'hanging',  '',         '',          'long'
        \,        'space',    'keep',     'pack',      'orphan']
  let fo.groups = ['autowrap', 'comments', 'reformat', 'reindent', 'multibyte']
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
        \, 'reformat'  : "all text (automatic)ally | (autocomments) , (manual) comments with gq"
        \, 'reindent'  : "number/bullet-(list)s | (hang)ing from second line of paragraph"
        \, 'multibyte' : "join-with-(space)s | join-with-(keep)-together | join-(pack)ed"
        \}

  " TODO: this might not be necessary, or be too complicated
  " The idea was to alert the user when &fo sub-options that depended on other
  " Vim options were set
  let fo.dependent_opts = {
        \  't' : 'textwidth'
        \, 'c' : 'textwidth'
        \, 'l' : 'textwidth'
        \, '1' : 'textwidth'
        \, 'n' : 'autoindent'
        \, '2' : 'autoindent'
        \ }

  " extra options tracked by WTF, like &ai, &tw, &com and &flp
  " NOTE: this is intended to either replace or complement the above
  let fo.extra_options = {}

  let fo.added_c_for_auto_comments = 0

  " for re-positioning the cursor after re-render()
  let fo.pos = []

  func fo.name(opt) dict
    return self.opts[stridx(self.known_opts, a:opt)]
  endfunc

  " Takes the buffer-number to act upon
  func fo.set_bufnr(...) dict
    if a:0
      let self.bufnr = a:1
    else
      let self.bufnr = bufnr('.')
    endif
    let opt_fo = getbufvar(self.bufnr, '&fo')
    for o in split(self.known_opts, '\zs')
      let self.opt['_' . o] = s:SubOpt(opt_fo, o)
    endfor
    " WTF doesn't respect old vi settings
    for o in split('wvb', '\zs')
      call self.remove(o)
    endfor
    " Collect the extra related options for wtf
    call self.set_opt('ai', getbufvar(self.bufnr, '&ai'))
    call self.set_opt('tw', getbufvar(self.bufnr, '&tw'))
    call self.set_opt('com', getbufvar(self.bufnr, '&com'))
    call self.set_opt('flp', getbufvar(self.bufnr, '&flp'))
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

  " TODO: NO! This needs to happen on bnum, not curbuf
  func fo.apply() dict
    exe 'set fo=' . self.to_option()
  endfunc

  func fo.set_opt(opt, val) dict
    let self.extra_options[a:opt] = a:val
  endfunc

  func fo.get_opt(opt) dict
    if a:opt == 'fo'
      return self.to_option()
    else
      return self.extra_options[a:opt]
    endif
  endfunc

  func fo.render() dict
    " delete any existing content
    % delete
    " Insert help and each formatoption group with choices
    let bnum  = self.bufnr
    let bname = bufname(self.bufnr)
    call append('$',   '" Showing &formatoption details for buffer ' . bnum . '.            {{{')
    call append('$', '"   ' . bname)
    call append('$', '" Each pair of lines show a &formatoption group')
    call append('$', '"   and the available choices it can take.')
    call append('$', '"   * Combinable choices separated by comma (,)')
    call append('$', '"   * Exclusive choices separated by pipe   (|)')
    call append('$', '" Edit each group line manually and press <CR> to update')
    call append('$', '"   the   set fo=...   line at the bottom of this window.')
    call append('$', '"   Yank this setting to use it in your desired buffer.')
    call append('$', '" Type :help wtf-groups for a more detailed explanation. }}}')
    call append('$', '')

    for g in self.groups
      let title = printf("%9s", g)
      if g == 'reformat'
        let group_opts_set = self.show_reformat()
      elseif g == 'reindent'
        let group_opts_set = self.show_reindent()
      else
        let group_opts_set = self.show(g)
      endif
      call append('$', title . ' : ' . group_opts_set)
      call append('$', repeat(' ', 12) . self.help(g, group_opts_set))
    endfor

    call append('$', '')
    call append('$', '" Options for ' . bname . ' (buffer ' . bnum . '):')
    call append('$', '" set fo='  . self.get_opt('fo'))
    call append('$', '" set ai='  . self.get_opt('ai'))
    call append('$', '" set tw='  . self.get_opt('tw'))
    call append('$', '" set com=' . self.get_opt('com'))
    call append('$', '" set flp=' . self.get_opt('flp'))

    " delete first line which is an artifact of using append('$')
    1
    delete

    if self.pos == []
      12
      normal! 03w
    else
      call setpos('.', self.pos)
    endif

    " reset 'modified', so that ":q" can be used to close the window
    setlocal nomodified ft=wtf-window
  endfunc

  func fo.cr() dict
    echo "hi from cr"
  endfunc

  func fo.space() dict
    let line = getline('.')
    if line =~ '^\s*\%(".*\)\?$'
      return
    elseif line =~ '^\s\s\+'
      let line = getline(line('.')-1)
    endif
    " TODO: doesn't handle toggling of | separated options correctly
    let opt = expand('<cword>')
    let group = substitute(line, '^\s*\(\w\+\)\s*:.*', '\1', '')
    let opts = s:ToggleOpt(matchstr(line, ':\s*\zs.*'), opt)
    exe 'call self.' . group . '(opts)'
    let self.pos = getpos('.')
    call self.render()
  endfunc

  func fo.setup_wtf_win() dict
    new wtf-window
    let b:wtf = self
    let self.wtf_win_bufnr = bufnr('.')
    setlocal noro buftype=nofile fdm=marker

    " Install autocommands to enable mappings in option-window
    noremap  <silent> <buffer> <CR>    <C-\><C-N>:call b:wtf.cr()<CR>
    inoremap <silent> <buffer> <CR>    <Esc>:call b:wtf.cr()<CR>
    noremap  <silent> <buffer> <Space> :call b:wtf.space()<CR>

    " Make the buffer be deleted when the window is closed.
    setlocal buftype=nofile bufhidden=delete noswapfile

    augroup wtfwin
      au! BufUnload,BufHidden wtf-window nested au! wtfwin
    augroup END

    call self.render()
  endfunc

  " Builder Interface - separated into logical formatoption groups

  " choices: comments, text, except-long, orphan-control
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

  " choices: automatic | autocomments , manual
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
    if choice =~? '\<m\%[anual]'
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
    if s =~ '|'
      if len(a:opts_set) > 0
        let s = substitute(s, '(\(\w\+\))', '(#\1#)', 'g')
      else
        let s = substitute(s, '(\(\w\+\))', '(-\1-)', 'g')
      endif
    else
      let s = substitute(s, '(\(\w\+\))', '(-\1-)', 'g')
    endif
    return s
  endfunc

  " these groups are special in the way options are combined
  func fo.show_reformat() dict
    let have_a = self.has('a')
    let have_c = self.has('c')
    let have_q = self.has('q')
    let group_opts = []
    if have_a && have_c
      call add(group_opts, 'autocomments')
    elseif have_a
      call add(group_opts, self.name('a'))
    endif
    if have_q
      call add(group_opts, self.name('q'))
    endif
    return join(group_opts, ',')
  endfunc

  func fo.show_reindent() dict
    if self.has('n')
      return 'list'
    elseif self.has('2')
      return 'hang'
    endif
    return ''
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
    for f in self.groups
      exe 'call self.' . f . '(' .  string(option_set[os]) . ')'
      let os += 1
    endfor
    call self.apply()
  endfunc

  func fo.vim_default() dict
    call self.wtf('comments,text', '', 'manual', '', '')
  endfunc

  call call(fo.set_bufnr, a:000, fo)
  return fo
endfunction

" Commands: {{{1
command! -nargs=0 -bar WTF call WTF().setup_wtf_win()

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
