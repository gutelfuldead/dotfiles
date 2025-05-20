autocmd BufRead,BufNewFile * if getline(1) =~# '^#/\(env \)\?bash' | setfiletype sh | endif
