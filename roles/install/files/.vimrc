set nu " 设置行号
colorscheme desert " 配色文件
syntax on " 语法检查
runtime! debian.vim
if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif

