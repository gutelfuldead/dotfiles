" VIM syntax file
" Language: IDD
" Maintainer: Jason Gutel
" https://vim.fandom.com/wiki/Creating_your_own_syntax_files#Install_the_syntax_file
" https://vim.fandom.com/wiki/User:Clearmoments/celstarcat

if exists("b:current_syntax") 
	finish
endif

" Keywords
syn match iddRealComment "#.*"

syn keyword iddBlockComment COMMENT nextgroup=iddMemberCommentString
syn match iddMemberComment " ; " nextgroup=iddMemberCommentString
syn match iddMemberCommentString ".*" contained

syn keyword iddPayloadBegin PAYLOADTAG_BEGIN
syn keyword iddPayloadEnd PAYLOADTAG_END
syn keyword iddMember MEMBER
syn keyword iddValue Unsigned8 Unsigned16 Unsigned32 Unsigned64 Signed8 Signed16 Signed32 Signed64 Float32 Float64 Nil
syn keyword iddInsertMember INSERT_MEMBERS

let b:current_syntax = "idd"
hi def link iddRealComment Comment
hi def link iddMemberComment PreProc
hi iddMemberCommentString ctermfg=109
hi def link iddBlockComment PreProc
hi def link iddPayloadBegin Statement
hi def link iddPayloadEnd Statement
hi def link iddMember Keyword
hi def link iddValue Type
hi def link iddInsertMember Special

