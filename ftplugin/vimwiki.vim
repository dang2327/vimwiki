" vim:tabstop=2:shiftwidth=2:expandtab:foldmethod=marker:textwidth=79
" Vimwiki filetype plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1  " Don't load another plugin for this buffer

" UNDO list {{{
" Reset the following options to undo this plugin.
let b:undo_ftplugin = "setlocal ".
      \ "suffixesadd< isfname< comments< ".
      \ "autowriteall< ".
      \ "formatoptions< foldtext< ".
      \ "foldmethod< foldexpr< commentstring< "
" UNDO }}}

filetype indent off

" MISC STUFF {{{

setlocal autowriteall
setlocal commentstring=%%%s

if g:vimwiki_conceallevel && exists("+conceallevel")
  let &conceallevel = g:vimwiki_conceallevel
endif

" MISC }}}

" GOTO FILE: gf {{{
execute 'setlocal suffixesadd='.VimwikiGet('ext')
setlocal isfname-=[,]
" gf}}}

" Autocreate list items {{{
" for list items, and list items with checkboxes
if VimwikiGet('syntax') == 'default'
  setl comments=b:*,b:#,b:-
  setl formatlistpat=^\\s*[*#-]\\s*
else
  setl comments=n:*,n:#
endif
setlocal formatoptions=tnro

if !empty(&langmap)
  " Valid only if langmap is a comma separated pairs of chars
  let l_o = matchstr(&langmap, '\C,\zs.\zeo,')
  if l_o
    exe 'nnoremap <buffer> '.l_o.' :call vimwiki#lst#kbd_oO("o")<CR>a'
  endif

  let l_O = matchstr(&langmap, '\C,\zs.\zeO,')
  if l_O
    exe 'nnoremap <buffer> '.l_O.' :call vimwiki#lst#kbd_oO("O")<CR>a'
  endif
endif

" COMMENTS }}}

" FOLDING for headers and list items using expr fold method. {{{
function! VimwikiFoldLevel(lnum) "{{{
  let line = getline(a:lnum)

  " Header folding...
  if line =~ g:vimwiki_rxHeader
    let n = vimwiki#base#count_first_sym(line)
    return '>'.n
  endif

  if g:vimwiki_fold_trailing_empty_lines == 0 && line =~ '^\s*$'
    let nnline = getline(nextnonblank(a:lnum + 1))
  else
    let nnline = getline(a:lnum + 1)
  endif
  if nnline =~ g:vimwiki_rxHeader
    let n = vimwiki#base#count_first_sym(nnline)
    return '<'.n
  endif

  " List item folding...
  if g:vimwiki_fold_lists
    let base_level = s:get_base_level(a:lnum)

    let rx_list_item = '\('.
          \ g:vimwiki_rxListBullet.'\|'.g:vimwiki_rxListNumber.
          \ '\)'


    if line =~ rx_list_item
      let [nnum, nline] = s:find_forward(rx_list_item, a:lnum)
      let level = s:get_li_level(a:lnum)
      let leveln = s:get_li_level(nnum)
      let adj = s:get_li_level(s:get_start_list(rx_list_item, a:lnum))

      if leveln > level
        return ">".(base_level+leveln-adj)
      else
        return (base_level+level-adj)
      endif
    else
      " process multilined list items
      let [pnum, pline] = s:find_backward(rx_list_item, a:lnum)
      if pline =~ rx_list_item
        if indent(a:lnum) > indent(pnum)
          let level = s:get_li_level(pnum)
          let adj = s:get_li_level(s:get_start_list(rx_list_item, pnum))

          let [nnum, nline] = s:find_forward(rx_list_item, a:lnum)
          if nline =~ rx_list_item
            let leveln = s:get_li_level(nnum)
            if leveln > level
              return (base_level+leveln-adj)
            endif
          endif

          return (base_level+level-adj)
        endif
      endif
    endif

    return base_level
  endif

  return -1
endfunction "}}}

function! s:get_base_level(lnum) "{{{
  let lnum = a:lnum - 1
  while lnum > 0
    if getline(lnum) =~ g:vimwiki_rxHeader
      return vimwiki#base#count_first_sym(getline(lnum))
    endif
    let lnum -= 1
  endwhile
  return 0
endfunction "}}}

function! s:find_forward(rx_item, lnum) "{{{
  let lnum = a:lnum + 1

  while lnum <= line('$')
    let line = getline(lnum)
    if line =~ a:rx_item
          \ || line =~ '^\S'
          \ || line =~ g:vimwiki_rxHeader
      break
    endif
    let lnum += 1
  endwhile

  return [lnum, getline(lnum)]
endfunction "}}}

function! s:find_backward(rx_item, lnum) "{{{
  let lnum = a:lnum - 1

  while lnum > 1
    let line = getline(lnum)
    if line =~ a:rx_item
          \ || line =~ '^\S'
      break
    endif
    let lnum -= 1
  endwhile

  return [lnum, getline(lnum)]
endfunction "}}}

function! s:get_li_level(lnum) "{{{
  if VimwikiGet('syntax') == 'media'
    let level = vimwiki#base#count_first_sym(getline(a:lnum))
  else
    let level = (indent(a:lnum) / &sw)
  endif
  return level
endfunction "}}}

function! s:get_start_list(rx_item, lnum) "{{{
  let lnum = a:lnum
  while lnum >= 1
    let line = getline(lnum)
    if line !~ a:rx_item && line =~ '^\S'
      return nextnonblank(lnum + 1)
    endif
    let lnum -= 1
  endwhile
  return 0
endfunction "}}}

function! VimwikiFoldText() "{{{
  let line = substitute(getline(v:foldstart), '\t',
        \ repeat(' ', &tabstop), 'g')
  return line.' ['.(v:foldend - v:foldstart).']'
endfunction "}}}

" FOLDING }}}

" COMMANDS {{{
command! -buffer Vimwiki2HTML
      \ w <bar> call vimwiki#html#Wiki2HTML(expand(VimwikiGet('path_html')),
      \                             expand('%'))
command! -buffer Vimwiki2HTMLBrowse
      \ w <bar> call VimwikiWeblinkHandler(
      \   vimwiki#html#Wiki2HTML(expand(VimwikiGet('path_html')),
      \                          expand('%')))
command! -buffer VimwikiAll2HTML
      \ call vimwiki#html#WikiAll2HTML(expand(VimwikiGet('path_html')))

command! -buffer VimwikiNextLink call vimwiki#base#find_next_link()
command! -buffer VimwikiPrevLink call vimwiki#base#find_prev_link()
command! -buffer VimwikiDeleteLink call vimwiki#base#delete_link()
command! -buffer VimwikiRenameLink call vimwiki#base#rename_link()
command! -buffer VimwikiFollowLink call vimwiki#base#follow_link('nosplit')
command! -buffer VimwikiGoBackLink call vimwiki#base#go_back_link()
command! -buffer VimwikiSplitLink call vimwiki#base#follow_link('split')
command! -buffer VimwikiVSplitLink call vimwiki#base#follow_link('vsplit')

command! -buffer VimwikiTabnewLink call vimwiki#base#follow_link('tabnew')

command! -buffer -range VimwikiToggleListItem call vimwiki#lst#ToggleListItem(<line1>, <line2>)

command! -buffer VimwikiGenerateLinks call vimwiki#base#generate_links()

exe 'command! -buffer -nargs=* VimwikiSearch lvimgrep <args> '.
      \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')

exe 'command! -buffer -nargs=* VWS lvimgrep <args> '.
      \ escape(VimwikiGet('path').'**/*'.VimwikiGet('ext'), ' ')

command! -buffer -nargs=1 VimwikiGoto call vimwiki#base#goto("<args>")

" table commands
command! -buffer -nargs=* VimwikiTable call vimwiki#tbl#create(<f-args>)
command! -buffer VimwikiTableAlignQ call vimwiki#tbl#align_or_cmd('gqq')
command! -buffer VimwikiTableAlignW call vimwiki#tbl#align_or_cmd('gww')
command! -buffer VimwikiTableMoveColumnLeft call vimwiki#tbl#move_column_left()
command! -buffer VimwikiTableMoveColumnRight call vimwiki#tbl#move_column_right()

" diary commands
command! -buffer VimwikiDiaryNextDay call vimwiki#diary#goto_next_day()
command! -buffer VimwikiDiaryPrevDay call vimwiki#diary#goto_prev_day()

" COMMANDS }}}

" KEYBINDINGS {{{
if g:vimwiki_use_mouse
  nmap <buffer> <S-LeftMouse> <NOP>
  nmap <buffer> <C-LeftMouse> <NOP>
  nnoremap <silent><buffer> <2-LeftMouse> :VimwikiFollowLink<CR>
  nnoremap <silent><buffer> <S-2-LeftMouse> <LeftMouse>:VimwikiSplitLink<CR>
  nnoremap <silent><buffer> <C-2-LeftMouse> <LeftMouse>:VimwikiVSplitLink<CR>
  nnoremap <silent><buffer> <RightMouse><LeftMouse> :VimwikiGoBackLink<CR>
endif


if !hasmapto('<Plug>Vimwiki2HTML')
  nmap <buffer> <Leader>wh <Plug>Vimwiki2HTML
endif
nnoremap <script><buffer>
      \ <Plug>Vimwiki2HTML :Vimwiki2HTML<CR>

if !hasmapto('<Plug>Vimwiki2HTMLBrowse')
  nmap <buffer> <Leader>whh <Plug>Vimwiki2HTMLBrowse
endif
nnoremap <script><buffer>
      \ <Plug>Vimwiki2HTMLBrowse :Vimwiki2HTMLBrowse<CR>

if !hasmapto('<Plug>VimwikiFollowLink')
  nmap <silent><buffer> <CR> <Plug>VimwikiFollowLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiFollowLink :VimwikiFollowLink<CR>

if !hasmapto('<Plug>VimwikiSplitLink')
  nmap <silent><buffer> <S-CR> <Plug>VimwikiSplitLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiSplitLink :VimwikiSplitLink<CR>

if !hasmapto('<Plug>VimwikiVSplitLink')
  nmap <silent><buffer> <C-CR> <Plug>VimwikiVSplitLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiVSplitLink :VimwikiVSplitLink<CR>

if !hasmapto('<Plug>VimwikiTabnewLink')
  nmap <silent><buffer> <D-CR> <Plug>VimwikiTabnewLink
  nmap <silent><buffer> <C-S-CR> <Plug>VimwikiTabnewLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiTabnewLink :VimwikiTabnewLink<CR>

if !hasmapto('<Plug>VimwikiGoBackLink')
  nmap <silent><buffer> <BS> <Plug>VimwikiGoBackLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiGoBackLink :VimwikiGoBackLink<CR>

if !hasmapto('<Plug>VimwikiNextLink')
  nmap <silent><buffer> <TAB> <Plug>VimwikiNextLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiNextLink :VimwikiNextLink<CR>

if !hasmapto('<Plug>VimwikiPrevLink')
  nmap <silent><buffer> <S-TAB> <Plug>VimwikiPrevLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiPrevLink :VimwikiPrevLink<CR>

if !hasmapto('<Plug>VimwikiDeleteLink')
  nmap <silent><buffer> <Leader>wd <Plug>VimwikiDeleteLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiDeleteLink :VimwikiDeleteLink<CR>

if !hasmapto('<Plug>VimwikiRenameLink')
  nmap <silent><buffer> <Leader>wr <Plug>VimwikiRenameLink
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiRenameLink :VimwikiRenameLink<CR>

if !hasmapto('<Plug>VimwikiToggleListItem')
  nmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
  vmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
  if has("unix")
    nmap <silent><buffer> <C-@> <Plug>VimwikiToggleListItem
  endif
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiToggleListItem :VimwikiToggleListItem<CR>

if !hasmapto('<Plug>VimwikiDiaryNextDay')
  nmap <silent><buffer> <C-Down> <Plug>VimwikiDiaryNextDay
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiDiaryNextDay :VimwikiDiaryNextDay<CR>

if !hasmapto('<Plug>VimwikiDiaryPrevDay')
  nmap <silent><buffer> <C-Up> <Plug>VimwikiDiaryPrevDay
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiDiaryPrevDay :VimwikiDiaryPrevDay<CR>

function! s:CR() "{{{
  let res = vimwiki#lst#kbd_cr()
  if res == "\<CR>" && g:vimwiki_table_auto_fmt
    let res = vimwiki#tbl#kbd_cr()
  endif
  return res
endfunction "}}}

" List and Table <CR> mapping
inoremap <buffer> <expr> <CR> <SID>CR()

" List mappings
nnoremap <buffer> o :<C-U>call vimwiki#lst#kbd_oO('o')<CR>
nnoremap <buffer> O :<C-U>call vimwiki#lst#kbd_oO('O')<CR>

" Table mappings
if g:vimwiki_table_auto_fmt
  inoremap <expr> <buffer> <Tab> vimwiki#tbl#kbd_tab()
  inoremap <expr> <buffer> <S-Tab> vimwiki#tbl#kbd_shift_tab()
endif

nnoremap <buffer> gqq :VimwikiTableAlignQ<CR>
nnoremap <buffer> gww :VimwikiTableAlignW<CR>
if !hasmapto('<Plug>VimwikiTableMoveColumnLeft')
  nmap <silent><buffer> <A-Left> <Plug>VimwikiTableMoveColumnLeft
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiTableMoveColumnLeft :VimwikiTableMoveColumnLeft<CR>
if !hasmapto('<Plug>VimwikiTableMoveColumnRight')
  nmap <silent><buffer> <A-Right> <Plug>VimwikiTableMoveColumnRight
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiTableMoveColumnRight :VimwikiTableMoveColumnRight<CR>

" Misc mappings
inoremap <buffer> <S-CR> <br /><CR>

" Text objects {{{
onoremap <silent><buffer> ah :<C-U>call vimwiki#base#TO_header(0, 0)<CR>
vnoremap <silent><buffer> ah :<C-U>call vimwiki#base#TO_header(0, 1)<CR>

onoremap <silent><buffer> ih :<C-U>call vimwiki#base#TO_header(1, 0)<CR>
vnoremap <silent><buffer> ih :<C-U>call vimwiki#base#TO_header(1, 1)<CR>

onoremap <silent><buffer> a\ :<C-U>call vimwiki#base#TO_table_cell(0, 0)<CR>
vnoremap <silent><buffer> a\ :<C-U>call vimwiki#base#TO_table_cell(0, 1)<CR>

onoremap <silent><buffer> i\ :<C-U>call vimwiki#base#TO_table_cell(1, 0)<CR>
vnoremap <silent><buffer> i\ :<C-U>call vimwiki#base#TO_table_cell(1, 1)<CR>

onoremap <silent><buffer> ac :<C-U>call vimwiki#base#TO_table_col(0, 0)<CR>
vnoremap <silent><buffer> ac :<C-U>call vimwiki#base#TO_table_col(0, 1)<CR>

onoremap <silent><buffer> ic :<C-U>call vimwiki#base#TO_table_col(1, 0)<CR>
vnoremap <silent><buffer> ic :<C-U>call vimwiki#base#TO_table_col(1, 1)<CR>

nnoremap <silent><buffer> = :call vimwiki#base#AddHeaderLevel()<CR>
nnoremap <silent><buffer> - :call vimwiki#base#RemoveHeaderLevel()<CR>

" }}}

" Danh Mod
" short forms for latex formatting and math elements. {{{
" taken from auctex.vim or miktexmacros.vim

" Insert emphasis DIV
call IMAP ('DIV', '<div class="emphasis"><++></div><++>', '')
call IMAP ('HIG', '<div class="highlight"><++></div><++>', '')
call IMAP ('=>', '$\Rightarrow$', '')
call IMAP ('-->', '$\rightarrow$', '')
" Align environment
call IMAP ('ALI', "\\begin{align*}\<cr><++>\<cr>\\end{align*}", '') 
call IMAP ('__', '_{<++>}<++>', '')
call IMAP ('()', '(<++>)<++>', '')
call IMAP ('[]', '[<++>]<++>', '')
call IMAP ('{}', '{<++>}<++>', '')
call IMAP ('^^', '^{<++>}<++>', '')
call IMAP ('$$', '$<++>$<++>', '')
call IMAP ('||', '|<++>|<++>', '')
" call IMAP ('==', '&=& ', '')
call IMAP ('~~', '&\approx& ', '')
call IMAP ('=~', '\approx', '')
" call IMAP ('::', '\dots', '') -- commented out for C++ namespace programming
call IMAP (g:mapleader.'(', '\left( <++> \right)<++>', '')
call IMAP (g:mapleader.'[', '\left[ <++> \right]<++>', '')
call IMAP (g:mapleader.'{', '\left\{ <++> \right\}<++>', '')
call IMAP (g:mapleader.',<', '\langle <++> \rangle<++>', '')
call IMAP ('\{', '\{ <++> \}<++>', '')
call IMAP (g:mapleader.'|', '\left| <++> \right|<++>', '')
call IMAP (g:mapleader.',|', '\left\| <++> \right\|<++>', '')

" \preformatted text
call IMAP ('{{{{', "{{{class=\"brush: <++>\"\<cr><++>\<cr>}}}<++>", '')

" Math map
call IMAP (g:mapleader.'$$', "$$\<cr><++>\<cr>$$\<cr><++>", '')
call IMAP (g:mapleader.', ', '\qquad ', '')
call IMAP (g:mapleader.',/', '\over ', '')
call IMAP (g:mapleader.'o', '\cdot', '')
call IMAP (g:mapleader.',o', '\cdots', '')

" Leader maps
call IMAP (g:mapleader.'^', '\hat{<++>}<++>', '')
call IMAP (g:mapleader.'_', '\bar{<++>}<++>', '')
call IMAP (g:mapleader.'6', '\partial', '')
call IMAP (g:mapleader.'8', '\infty', '')
call IMAP (g:mapleader.'/', '\frac{<++>}{<++>}<++>', '')
call IMAP (g:mapleader.'%', '\frac{<++>}{<++>}<++>', '')
call IMAP (g:mapleader.'@', '\circ', '')
call IMAP (g:mapleader.'0', '^\circ', '')
call IMAP (g:mapleader.'=', '\equiv', '')
call IMAP (g:mapleader."\\",'\setminus', '')
call IMAP (g:mapleader.'*', '\times', '')
call IMAP (g:mapleader.'&', '\wedge', '')
call IMAP (g:mapleader.'-', '\bigcap', '')
call IMAP (g:mapleader.'+', '\bigcup', '')
call IMAP (g:mapleader.'M', '\sum_{<++>}^{<++>}<++>', '')
" call IMAP (g:mapleader.'(', '\subset', '')
call IMAP (g:mapleader.')', '\supset', '')
call IMAP (g:mapleader.'<', '\le', '')
call IMAP (g:mapleader.'>', '\ge', '')
"call IMAP (g:mapleader.',', '\nonumber', '')   Disabled
call IMAP (g:mapleader.'~', '\tilde{<++>}<++>', '')
call IMAP (g:mapleader.';', '\dot{<++>}<++>', '')
call IMAP (g:mapleader.':', '\ddot{<++>}<++>', '')
call IMAP (g:mapleader.'2', '\sqrt{<++>}<++>', '')
" call IMAP (g:mapleader.'|', '\Big|', '')      Disabled
call IMAP (g:mapleader.'I', "\\int_{<++>}^{<++>}<++>", '')
" Danh's Macro
" \mathbf
call IMAP (g:mapleader.'BF', "\\mathbf{<++>}<++>", '')
" \mathrm
call IMAP (g:mapleader.'RM', "\\mathrm{<++>}<++>", '')
" \mathbb
call IMAP (g:mapleader.'BB', "\\mathbb{<++>}<++>", '')
" \mathcal
call IMAP (g:mapleader.'CA', "\\mathcal{<++>}<++>", '')
" \text
call IMAP (g:mapleader.'TE', "\\text{<++>}<++>", '')
" \textbf
call IMAP (g:mapleader.'TB', "\\textbf{<++>}<++>", '')
" \textit
call IMAP (g:mapleader.'TI', "\\textit{<++>}<++>", '')
" }}}
" Greek Letters {{{
call IMAP(g:mapleader.'a', '\alpha', '')
call IMAP(g:mapleader.'b', '\beta', '')
call IMAP(g:mapleader.'c', '\chi', '')
call IMAP(g:mapleader.'d', '\delta', '')
call IMAP(g:mapleader.'e', '\varepsilon', '')
call IMAP(g:mapleader.'f', '\varphi', '')
call IMAP(g:mapleader.'g', '\gamma', '')
call IMAP(g:mapleader.'h', '\eta', '')
call IMAP(g:mapleader.'k', '\kappa', '')
call IMAP(g:mapleader.'l', '\lambda', '')
call IMAP(g:mapleader.'m', '\mu', '')
call IMAP(g:mapleader.'n', '\nu', '')
call IMAP(g:mapleader.'p', '\pi', '')
call IMAP(g:mapleader.'q', '\theta', '')
call IMAP(g:mapleader.'r', '\rho', '')
call IMAP(g:mapleader.'s', '\sigma', '')
call IMAP(g:mapleader.'t', '\tau', '')
call IMAP(g:mapleader.'u', '\upsilon', '')
call IMAP(g:mapleader.'v', '\varsigma', '')
call IMAP(g:mapleader.'w', '\omega', '')
" call IMAP(g:mapleader.'w', '\wedge', '')  " AUCTEX style
call IMAP(g:mapleader.'x', '\xi', '')
call IMAP(g:mapleader.'y', '\psi', '')
call IMAP(g:mapleader.'z', '\zeta', '')
" not all capital greek letters exist in LaTeX!
" reference: http://www.giss.nasa.gov/latex/ltx-405.html
call IMAP(g:mapleader.'D', '\Delta', '')
call IMAP(g:mapleader.'F', '\Phi', '')
call IMAP(g:mapleader.'G', '\Gamma', '')
call IMAP(g:mapleader.'Q', '\Theta', '')
call IMAP(g:mapleader.'L', '\Lambda', '')
call IMAP(g:mapleader.'X', '\Xi', '')
call IMAP(g:mapleader.'Y', '\Psi', '')
call IMAP(g:mapleader.'S', '\Sigma', '')
call IMAP(g:mapleader.'U', '\Upsilon', '')
call IMAP(g:mapleader.'W', '\Omega', '')
" }}}
" ProtectLetters: sets up indentity maps for things like ``a {{{
" " Description: If we simply do
" 		call IMAP('`a', '\alpha', '')
" then we will never be able to type 'a' after a tex-quotation. Since
" IMAP() always uses the longest map ending in the letter, this problem
" can be avoided by creating a fake map for ``a -> ``a.
" This function sets up fake maps of the following forms:
" 	``[aA]  -> ``[aA]    (for writing in quotations)
" 	\`[aA]  -> \`[aA]    (for writing diacritics)
" 	"`[aA]  -> "`[aA]    (for writing german quotations)
" It does this for all printable lower ascii characters just to make sure
" we dont let anything slip by.
function! s:ProtectLetters(first, last)
  let i = a:first
  while i <= a:last
    if nr2char(i) =~ '[[:print:]]'
      call IMAP('``'.nr2char(i), '``'.nr2char(i), '')
      call IMAP('\`'.nr2char(i), '\`'.nr2char(i), '')
      call IMAP('"`'.nr2char(i), '"`'.nr2char(i), '')
    endif
    let i = i + 1
  endwhile
endfunction 
call s:ProtectLetters(32, 127)
" }}}
" vmaps: enclose selected region in brackets, environments {{{ 
" The action changes depending on whether the selection is character-wise
" or line wise. for example, selecting linewise and pressing \v will
" result in the region being enclosed in \begin{verbatim}, \end{verbatim},
" whereas in characterise visual mode, the thingie is enclosed in \verb|
" and |.
exec 'vnoremap <silent> '.g:mapleader."( \<C-\\>\<C-N>:call VEnclose('\\left( ', ' \\right)', '\\left(', '\\right)')\<CR>"
exec 'vnoremap <silent> '.g:mapleader."[ \<C-\\>\<C-N>:call VEnclose('\\left[ ', ' \\right]', '\\left[', '\\right]')\<CR>"
exec 'vnoremap <silent> '.g:mapleader."{ \<C-\\>\<C-N>:call VEnclose('\\left\\{ ', ' \\right\\}', '\\left\\{', '\\right\\}')\<CR>"
exec 'vnoremap <silent> '.g:mapleader."$ \<C-\\>\<C-N>:call VEnclose('$', '$', '\\[', '\\]')\<CR>"
" }}}

" }}}

" KEYBINDINGS }}}

" AUTOCOMMANDS {{{
if VimwikiGet('auto_export')
  " Automatically generate HTML on page write.
  augroup vimwiki
    au BufWritePost <buffer> Vimwiki2HTML
  augroup END
endif

" AUTOCOMMANDS }}}
