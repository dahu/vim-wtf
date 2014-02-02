" Vim syntax file
" FileType: wtf-window (WhatTheFormatoptions Interactive Window)
" Maintainer: Barry Arthur <barry.arthur@gmail.com>
" License: This file can be redistribued and/or modified under the same terms
"   as Vim itself.
"
" Version: 0.1
" Last Change: 2014-02-02

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  " TODO: uncomment this
  " finish
endif

syn match wtfGroupName     '\w\+\ze\s*:'
syn match wtfGroupOptions  ':\s*\zs.*'
syn match wtfGroupEnabled  '(+\w\++)'
syn match wtfGroupDisabled '(-\w\+-)'

command -nargs=+ HiLink hi def link <args>

HiLink wtfGroupName          Type
HiLink wtfGroupOptions       Special
HiLink wtfGroupEnabled       Underlined
HiLink wtfGroupDisabled      NonText

delcommand HiLink
let b:current_syntax = "wtf"

" vim: nowrap sw=2 sts=2 ts=8 ff=unix:
