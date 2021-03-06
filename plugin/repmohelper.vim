" File:		D2254.vim
" Created:	2017 Dec 10
" Last Change:	2017 Dec 11
" Version:      0.2
" Author:	Andy Wokula <anwoku@yahoo.de>
" License:	Vim License, see :h license

com!              -nargs=? EchoRepmoSelfMap  :echo join(repmohelper#SelfKeyMapStatements(<q-args>), "\n")
com!              -nargs=? EchoRepmoMap      :echo join(repmohelper#KeyMapStatements(<q-args>), "\n")
                                            
com! -bang -range -nargs=? PutRepmoSelfMap  :call repmohelper#PutValue(repmohelper#SelfKeyMapStatements(<q-args>), <line2>, <bang>0)
com! -bang -range -nargs=? PutRepmoMap      :call repmohelper#PutValue(repmohelper#KeyMapStatements(<q-args>), <line2>, <bang>0)
