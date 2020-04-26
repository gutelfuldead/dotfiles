setlocal tabstop=4
setlocal shiftwidth=4
setlocal expandtab

" for taglist
let g:tlist_vhdl_settings   = 'vhdl;d:package declarations;b:package bodies;e:entities;a:architecture specifications;t:type declarations;p:processes;f:functions;r:procedures'

" set comment string for vhdl files
autocmd FileType vhdl setlocal commentstring=--\ %s

"""" shortcuts
vnoremap <leader>a :Align ": " := <=<CR>gv:s/:  /: /g<CR>:noh<CR>
vnoremap <leader>A :Align =><CR>:noh<CR>

"""""" MACROS

" Copy ports from a component and turns them into signals
" INPUT Line  : 'clk : IN    std_logic;'
" OUTPUT Line : 'signal clk : std_logic;'
:let @b="^isignal \<esc>eeebdwj^"

" converts component name into instantiation
" INPUT Line  : 'COMPONENT test_component IS'
" OUTPUT Line : 'test_component_inst : test_component'
:let @c="^\<esc>dwveyea_inst : \<esc>pwdw^\<esc>j^"

" After copying a component for instantiation running this over each of the
" IN/OUT arguments converts them to assignments of the same name
" INPUT Line  : 'bits_out      : OUT std_logic_vector(31 DOWNTO 0)'
" OUTPUT Line : 'bits_out      => bits_out,'
:let @d="^eeDa=> \<esc>^veyeepa,\<esc>bi \<esc>j"

" abbreviations
iabbr ,, <=
iabbr .. =>
iabbr dt downto
iabbr sig signal
iabbr gen generate
iabbr ot others
iabbr sl std_logic
iabbr slv std_logic_vector
iabbr uns unsigned
iabbr toi to_integer
iabbr tos to_signed
iabbr tou to_unsigned

" initializes std_logic and std_logic_vectors to all zeros
function! InitLogicZero()
	:%s/:\_\s*std_logic\_\s*;/: std_logic := '0';/g
	" only works on slvs(number downto number)
	:%s/:\_\s*std_logic_vector(\([0-9]*\) downto \([0-9]*\))\_\s*;/: std_logic_vector(\1 downto \2) := (others => '0');/g
	:%s/:\_\s*std_logic_vector(\([0-9]*\) to \([0-9]*\))\_\s*;/: std_logic_vector(\1 to \2) := (others => '0');/g
	:%s/:\_\s*unsigned(\([0-9]*\) downto \([0-9]*\))\_\s*;/: unsigned(\1 downto \2) := (others => '0');/g
	:%s/:\_\s*unsigned(\([0-9]*\) to \([0-9]*\))\_\s*;/: unsigned(\1 to \2) := (others => '0');/g
	" replaces anything using math in operators
	:%s/:\_\s*std_logic_vector(\([a-zA-Z0-9]*\)\_\s*-\_\s*\([a-zA-Z0-9]*\) downto \([a-zA-Z0-9]*\))\_\s*;/: std_logic_vector(\1-\2 downto \3) := (others => '0');/g
	:%s/:\_\s*std_logic_vector(\([a-zA-Z0-9]*\) to \([a-zA-Z0-9]*\)\_\s*-\_\s*\([a-zA-Z0-9]*\))\_\s*;/: std_logic_vector(\1 to \2-\3) := (others => '0');/g
	:%s/:\_\s*unsigned(\([a-zA-Z0-9]*\)\_\s*-\_\s*\([a-zA-Z0-9]*\) downto \([a-zA-Z0-9]*\))\_\s*;/: unsigned(\1-\2 downto \3) := (others => '0');/g
	:%s/:\_\s*unsigned(\([a-zA-Z0-9]*\) to \([a-zA-Z0-9]*\)\_\s*-\_\s*\([a-zA-Z0-9]*\))\_\s*;/: unsigned(\1 to \2-\3) := (others => '0');/g
	:noh<CR>
endfunction
map <leader>i :call InitLogicZero()<CR>

" formats wrt capitalization and spacing 
function! VHDLFormat()
	:retab
	:%s/\<IF\>/if/g
	:%s/if(/if (/g
	:%s/\<ELSIF\>/elsif/g
	:%s/elsif(/elsif (/g
	:%s/case(/case (/g
	:%s/\<IN\>/in/g
	:%s/\<in\>\s*/in    /g
	:%s/\<MAP\>/map/g
	:%s/map(/map (/g
	:%s/\<OUT\>/out/g
	:%s/: out /:   out /g
	:%s/\<OF\>/of/g
	:%s/\<ARCHITECTURE\>/architecture/g
	:%s/\<ATTRIBUTE\>/attribute/g
	:%s/\<BOOLEAN\>/boolean/g
	:%s/\<WHEN\>/when/g
	:%s/\<STRING\>/string/g
	:%s/\<ELSE\>/else/g
	:%s/\<ENTITY\>/entity/g
	:%s/\<LOOP\>/loop/g
	:%s/\<THEN\>/then/g
	:%s/\<CASE\>/case/g
	:%s/\<END\>/end/g
	:%s/\<INTEGER\>/integer/g
	:%s/\<PROCESS\>/process/g
	:%s/\<OTHERS\>/others/g
	:%s/\<GENERIC\>/generic/g
	:%s/\<PORT\>/port/g
	:%s/\<STD_LOGIC\>/std_logic/g
	:%s/\<STD_LOGIC_VECTOR\>/std_logic_vector/g
	:%s/\<COMPONENT\>/component/g
	:%s/\<AND\>/and/g
	:%s/\<OR\>/or/g
	:%s/\<XOR\>/xor/g
	:%s/\<NOT\>/not/g
	:%s/\<OPEN\>/open/g
	:%s/\<TRUE\>/true/g
	:%s/\<FALSE\>/false/g
	:%s/\<SIGNAL\>/signal/g
	:%s/\<VARIABLE\>/variable/g
	:%s/\<CONSTANT\>/constant/g
	:%s/\<GENERATE\>/generate/g
	:%s/\<RETURN\>/return/g
	:%s/\<TYPE\>/type/g
	:%s/\<SUBTYPE\>/subtype/g
	:%s/\<IS\>/is/g
	:%s/\<DOWNTO\>/downto/g
	:%s/\<PACKAGE\>/package/g
	:%s/\<USE\>/use/g
	:%s/\<ALL\>/all/g
	:%s/\<LIBRARY\>/library/g
	:%s/\<BEGIN\>/begin/g
	:%s/\<RECORD\>/record/g
	:%s/\<FUNCTION\>/function/g
	:%s/\<PROCEDURE\>/procedure/g
	:%s/\<WAIT\>/wait/g
	:%s/\<UNTIL\>/until/g
	:%s/\<FOR\>/for/g
	:%s/\<ON\>/on/g
	:%s/\<TO\>/to/g
	:%s/\<TIME\>/time/g
	:%s/\<ASSERT\>/assert/g
	:%s/\<REPORT\>/report/g
	:%s/\<INTEGER\>/integer/g
	:%s/\<RANGE\>/range/g
	:%s/\<ENTITY\>/entity/g
	:%s/\<WHILE\>/while/g
	:noh<CR>
endfunction
map <leader>f :call VHDLFormat()<CR>
