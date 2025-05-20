autocmd BufRead,BufNewFile * if getline(1) =~# '^#micropython' | setfiletype python | endif
