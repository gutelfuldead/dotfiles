setlocal tabstop=4
setlocal softtabstop=4
setlocal shiftwidth=4
setlocal expandtab

vnoremap <leader>a :Align = <CR>

function! PyFormat()
    :retab
    :%s/if(/if (/g
    :noh
endfunction
map <leader>f :call PyFormat()<CR>
