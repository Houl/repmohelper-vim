" File:		repmosetup.vim
" Created:	2017 Dec 06
" Last Change:	2017 Dec 11
" Version:      0.4
" Author:	Andy Wokula <anwoku@yahoo.de>
" License:	Vim License, see :h license

let s:sav_cpo=&cpo|set cpo&vim


if !exists("g:repmohelper_creator_comment")
    let g:repmohelper_creator_comment = 1
endif


let s:single_mode_chars = ['n', 'v', 'o', 'x']
let s:mode_char_pat = '^\C['. join(s:single_mode_chars). ']\+$'

let s:modifiers = {'<buffer>': '<buffer>', '<global>': '', '<b>': '<buffer>', '<g>': ''}
" currently only fixed combinations of modifiers possible

let s:key_placeholder = '<_>'
let s:key_placeholder_pat = escape(s:key_placeholder, '\.*$^~[')


" Key Mapping Helpers:

func! repmohelper#SelfKeyMapStatements(selfkeypairs, ...) "{{{
    " {selfkeypairs}	if (string): 'key1|revkey1 key2|revkey2 <buffer> nvo ...'
    let statements = s:MapStatements(s:noremap, [2], a:selfkeypairs, get(a:, 1, 1))
    if !g:repmohelper_creator_comment || type(a:selfkeypairs) != 1
        return statements
    else
        return insert(statements, '" :PutRepmoSelfMap '. a:selfkeypairs)
    endif
endfunc "}}}

func! repmohelper#KeyMapStatements(keytuples, ...) "{{{
    " {keytuples}	if (string): 'key1|revkey1|rhs1|revrhs1 key2|revkey2|... '
    let statements = s:MapStatements(s:remap, [2,4], a:keytuples, get(a:, 1, 1))
    if !g:repmohelper_creator_comment || type(a:keytuples) != 1
        return statements
    else
        return insert(statements, '" :PutRepmoMap '. a:keytuples)
    endif
endfunc "}}}

func! repmohelper#Split(val, ...) "{{{
    " {val}	(string) or (list of string) or (list of (list of string)) or mixed
    " {a:1}	(list of number) allowed lengths (2 or greater)
    " {a:2}	(list of string) allowed modes
    let expected_lengths = get(a:, 1, [])
    let combo_modes = get(a:, 2, ['nvo', 'nxo'])
    return s:Split(a:val, expected_lengths, combo_modes)
endfunc "}}}


func! s:MapStatements(func_dict, expected_lengths, selfkeypairs, with_checks) "{{{
    let stm_list = []
    let modifiers = ''
    let modes = 'nxo'
    let globals = {'rhs_template': '<Plug>(foo-<_>)', 'unmap_modifier': ''}
    for row in s:Split(a:selfkeypairs, (a:with_checks ? a:expected_lengths : []), keys(a:func_dict.combo))
	if index(a:expected_lengths, len(row)) >= 0
	    if has_key(a:func_dict.combo, modes)
		call extend(stm_list, call(a:func_dict.combo[modes], [modifiers] + row[0 : max(a:expected_lengths)-1], globals))
	    else
		for modechar in split(modes, '\L*')
		    call extend(stm_list, call(a:func_dict.single.MapStm, [modechar, modifiers] + row[0 : max(a:expected_lengths)-1], globals))
		endfor
	    endif
	elseif !empty(row)
	    if has_key(s:modifiers, row[0])
		let modifiers = s:modifiers[row[0]]
		let globals.unmap_modifier = stridx(modifiers, '<buffer>') >= 0 ? ' <buffer>' : ''
	    elseif stridx(row[0], s:key_placeholder) >= 0
		let globals.rhs_template = row[0]
	    elseif row[0] =~ s:mode_char_pat || has_key(a:func_dict.combo, row[0])
		let modes = row[0]
	    endif
	endif
    endfor
    return stm_list
endfunc "}}}

func! s:Split(val, expected_lengths, combo_modes) "{{{
    let special_names = a:combo_modes + s:single_mode_chars + keys(s:modifiers)
    let list = type(a:val) <= 1 ? split(a:val) : copy(a:val)
    let expr = printf(!empty(a:expected_lengths) ? 's:CheckTuple(%s, a:expected_lengths, special_names)' : '%s', 'type(v:val) <= 1 ? split(v:val, "|") : v:val')
    return map(list, expr)
endfunc "}}}

func! s:CheckTuple(val, expected_lengths, special_names) "{{{
    " {expected_lengths}	(list of number) list of (1 or greater)
    " {special_names}		(list of string) allowed items when length of {val} is 1
    let len = len(a:val)
    if type(a:val) == 3 && (index(a:expected_lengths, len)>=0 || len == 1 && (a:val[0] =~ s:mode_char_pat || index(a:special_names, a:val[0]) >= 0 || stridx(a:val[0], s:key_placeholder) >= 0))
	return a:val
    endif
    echohl WarningMsg
    try
	if type(a:val) != 3
	    echomsg 'Repmo: list expected: '. string(a:val)
	    return repeat(['<?>'], min(a:expected_lengths))
	elseif len == 1
	    echomsg printf('Repmo: mode char(s) or <modifier> not supported, or template not containing %s, or missing `|''-separated item: %s', s:key_placeholder, string(a:val[0]))
	    return []
	elseif index(a:expected_lengths, len) < 0
	    echomsg printf('Repmo: got %d items, expected %s: %s', len, join(a:expected_lengths, ' or '), string(a:val))
	    return (a:val + repeat(['<?>'], min(a:expected_lengths)))[0 : min(a:expected_lengths)-1]
	endif
	return a:val
    finally
	echohl None
    endtry
endfunc "}}}



let s:noremap = {'combo': {}, 'single': {}}

func! s:noremap.combo.nvo(mods, fkey, bkey) "{{{
    return s:noremap.single.MapStm('', a:mods, a:fkey, a:bkey)
endfunc "}}}

func! s:noremap.combo.nxo(mods, fkey, bkey) "{{{
    return [
	\ printf('noremap <expr>%s %s repmo#SelfKey(%s, %s)|sunmap%s %s', a:mods, a:fkey, string(a:fkey), string(a:bkey), self.unmap_modifier, a:fkey),
	\ printf('noremap <expr>%s %s repmo#SelfKey(%s, %s)|sunmap%s %s', a:mods, a:bkey, string(a:bkey), string(a:fkey), self.unmap_modifier, a:bkey),
	\ ]
endfunc "}}}

func! s:noremap.single.MapStm(modechar, mods, fkey, bkey) "{{{
    return [
	\ printf('%snoremap <expr>%s %s repmo#SelfKey(%s, %s)', a:modechar, a:mods, a:fkey, string(a:fkey), string(a:bkey)),
	\ printf('%snoremap <expr>%s %s repmo#SelfKey(%s, %s)', a:modechar, a:mods, a:bkey, string(a:bkey), string(a:fkey)),
	\ ]
endfunc "}}}


let s:remap = {'combo': {}, 'single': {}}

func! s:remap.combo.nvo(mods, fkey, bkey, ...) "{{{
    return call('s:remap.single.MapStm', ['', a:mods, a:fkey, a:bkey] + a:000)
endfunc "}}}

func! s:remap.combo.nxo(mods, fkey, bkey, ...) "{{{
    let frhs = a:0>=1 ? a:1 : s:FillTemplate(self.rhs_template, a:fkey)
    let brhs = a:0>=2 ? a:2 : s:FillTemplate(self.rhs_template, a:bkey)
    return [
	\ printf('map <expr>%s %s repmo#Key(%s, %s)|sunmap%s %s', a:mods, a:fkey, string(frhs), string(brhs), self.unmap_modifier, a:fkey),
	\ printf('map <expr>%s %s repmo#Key(%s, %s)|sunmap%s %s', a:mods, a:bkey, string(brhs), string(frhs), self.unmap_modifier, a:bkey),
	\ ]
endfunc "}}}

func! s:remap.single.MapStm(modechar, mods, fkey, bkey, ...) "{{{
    let frhs = a:0>=1 ? a:1 : s:FillTemplate(self.rhs_template, a:fkey)
    let brhs = a:0>=2 ? a:2 : s:FillTemplate(self.rhs_template, a:bkey)
    return [
	\ printf('%smap <expr>%s %s repmo#Key(%s, %s)', a:modechar, a:mods, a:fkey, string(frhs), string(brhs)),
	\ printf('%smap <expr>%s %s repmo#Key(%s, %s)', a:modechar, a:mods, a:bkey, string(brhs), string(frhs)),
	\ ]
endfunc "}}}

func! s:FillTemplate(template, val) "{{{
    return substitute(a:template, s:key_placeholder_pat, escape(a:val, '&~\'), '')
endfunc "}}}

let &cpo=s:sav_cpo|unlet s:sav_cpo
