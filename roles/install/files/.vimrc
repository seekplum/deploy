set nu " 设置行号
colorscheme desert " 配色文件
syntax on " 语法检查
runtime! debian.vim
if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif
set fileencodings=utf-8,gbk,utf-16le,cp1252,iso-8859-15,ucs-bom
set termencoding=utf-8
set encoding=utf-8

