"=============================================================================
" FILE: util.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
" Last Modified: 27 Jan 2013.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:is_windows = has('win16') || has('win32') || has('win64')
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \   (!isdirectory('/proc') && executable('sw_vers')))

function! neobundle#util#substitute_path_separator(path) "{{{
  return (s:is_windows && a:path =~ '\\') ?
        \ substitute(a:path, '\\', '/', 'g') : a:path
endfunction"}}}
function! neobundle#util#expand(path) "{{{
  let path = expand(escape(a:path, '*?{}'), 1)
  return (s:is_windows && path =~ '\\') ?
        \ neobundle#util#substitute_path_separator(path) : path
endfunction"}}}
function! neobundle#util#expand2(path) "{{{
  return expand(escape(a:path, '*?{}'), 1)
endfunction"}}}

function! neobundle#util#is_windows() "{{{
  return s:is_windows
endfunction"}}}
function! neobundle#util#is_mac() "{{{
  return s:is_mac
endfunction"}}}
function! neobundle#util#is_cygwin() "{{{
  return s:is_cygwin
endfunction"}}}

" Check vimproc. "{{{
function! neobundle#util#has_vimproc() "{{{
  if !exists('s:exists_vimproc')
    try
      call vimproc#version()
    catch
    endtry

    let s:exists_vimproc =
          \ (exists('g:vimproc_dll_path') && filereadable(g:vimproc_dll_path))
          \ || (exists('g:vimproc#dll_path') && filereadable(g:vimproc#dll_path))
  endif

  return s:exists_vimproc
endfunction"}}}
"}}}
" iconv() wrapper for safety.
function! s:iconv(expr, from, to) "{{{
  if a:from == '' || a:to == '' || a:from ==? a:to
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return result != '' ? result : a:expr
endfunction"}}}
function! neobundle#util#system(str, ...) "{{{
  let command = a:str
  let input = a:0 >= 1 ? a:1 : ''
  let command = s:iconv(command, &encoding, 'char')
  let input = s:iconv(input, &encoding, 'char')

  if a:0 == 0
    let output = neobundle#util#has_vimproc() ?
          \ vimproc#system(command) : system(command)
  elseif a:0 == 1
    let output = neobundle#util#has_vimproc() ?
          \ vimproc#system(command, input) : system(command, input)
  else
    " ignores 3rd argument unless you have vimproc.
    let output = neobundle#util#has_vimproc() ?
          \ vimproc#system(command, input, a:2) : system(command, input)
  endif

  let output = s:iconv(output, 'char', &encoding)

  return substitute(output, '\n$', '', '')
endfunction"}}}
function! neobundle#util#get_last_status() "{{{
  return neobundle#util#has_vimproc() ?
        \ vimproc#get_last_status() : v:shell_error
endfunction"}}}

" Split a comma separated string to a list.
function! neobundle#util#split_rtp(...) "{{{
  let rtp = a:0 ? a:1 : &runtimepath
  if type(rtp) == type([])
    return rtp
  endif

  if rtp !~ '\\'
    return split(rtp, ',')
  endif

  let split = split(rtp, '\\\@<!\%(\\\\\)*\zs,')
  return map(split,'substitute(v:val, ''\\\([\\,]\)'', "\\1", "g")')
endfunction"}}}

function! neobundle#util#join_rtp(list, runtimepath, rtp) "{{{
  return (a:runtimepath !~ '\\' && a:rtp !~ ',') ?
        \ join(a:list, ',') : join(map(copy(a:list), 's:escape(v:val)'), ',')
endfunction"}}}

" Removes duplicates from a list.
function! neobundle#util#uniq(list, ...) "{{{
  let list = a:0 ? map(copy(a:list), printf('[v:val, %s]', a:1)) : copy(a:list)
  let i = 0
  let seen = {}
  while i < len(list)
    let key = string(a:0 ? list[i][1] : list[i])
    if has_key(seen, key)
      call remove(list, i)
    else
      let seen[key] = 1
      let i += 1
    endif
  endwhile
  return a:0 ? map(list, 'v:val[0]') : list
endfunction"}}}

function! neobundle#util#set_default(var, val, ...)  "{{{
  if !exists(a:var) || type({a:var}) != type(a:val)
    let alternate_var = get(a:000, 0, '')

    let {a:var} = exists(alternate_var) ?
          \ {alternate_var} : a:val
  endif
endfunction"}}}
function! neobundle#util#set_dictionary_helper(variable, keys, pattern) "{{{
  for key in split(a:keys, '\s*,\s*')
    if !has_key(a:variable, key)
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}

function! neobundle#util#get_filetypes() "{{{
  let filetype = exists('*neocomplcache#get_context_filetype') ?
        \ neocomplcache#get_context_filetype(1) : &filetype
  return split(filetype, '\.')
endfunction"}}}

function! neobundle#util#convert_list(expr) "{{{
  return type(a:expr) ==# type([]) ? a:expr : [a:expr]
endfunction"}}}

" Escape a path for runtimepath.
function! s:escape(path)
  return substitute(a:path, ',\|\\,\@=', '\\\0', 'g')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker

