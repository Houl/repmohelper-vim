# repmohelper-vim
Easier mass-creation of [repmo](https://github.com/Houl/repmo-vim) keys, see [help](doc/repmohelper.txt).

Sorry, assumes existent `:PutExpr` (actually `:put =` should do it, but it needs escaping of `|` and `"`).  It's defined like

    com! -bang -range -nargs=1 -complete=expression PutExpr :call PutExpr(<args>, <line2>, <bang>0)

    func! PutExpr(expr, ...)
        let alnum = a:0>=1 ? a:1 : line('.')
        let bang = a:0>=2 ? !!a:2 : 0
        let lines = type(a:expr) <= 1 ? split(a:expr, "\n") : a:expr
        let lnum = max([0, alnum - (bang ? 1 : 0)])
        if empty(lines)
            return
        endif
        call append(lnum, lines)
    endfunc
