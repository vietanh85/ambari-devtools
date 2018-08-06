#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include-vagrant.sh"

# setup screenfetch for fun
yum install -y git
cd /var/lib
git clone https://github.com/KittyKatt/screenFetch.git
chmod +x screenFetch/screenfetch-dev
echo "/var/lib/screenFetch/screenfetch-dev" >> ~/$profileFile

yum install -y wget
yum install -y telnet
yum install -y unzip

# install and relink vim
yum install -y vim
if [ -f "/usr/bin/vi" ]; then
  rm /usr/bin/vi
fi

ln -s /usr/bin/vim /usr/bin/vi
if [ ! -d "~/.vim/colors" ]; then
  mkdir -p ~/.vim/colors
fi

wget -O ~/.vim/colors/dracula.vim https://raw.githubusercontent.com/dracula/vim/master/colors/dracula.vim
wget -O ~/.vim/colors/stormpetrel.vim https://raw.githubusercontent.com/nightsense/seabird/master/colors/stormpetrel.vim

echo "
syntax on
color stormpetrel

set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

set number
set showcmd

filetype indent on
set wildmenu
set lazyredraw

set showmatch
set incsearch
set hlsearch
nnoremap <leader><space> :nohlsearch<CR>
" > ~/.vimrc

echo "PS1='\[\033[36m\][\u@\h \W]\$ \[\033[0m\]'" >> ~/.bashrc

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- htop is better than top
case "$centOSVersion" in
  6*) EPEL_RPM=epel-release-6-8.noarch.rpm ;;
  7*) EPEL_RPM=epel-release-7-11.noarch.rpm ;;
  *)
    echo "CentOS $centOSVersion is not recognized!"
    exit 1
esac

wget dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/$EPEL_RPM
rpm -ihv $EPEL_RPM
yum install -y htop
rm $EPEL_RPM
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=

# neat little memory profiler
echo "

mem()
{
    ps -eo rss,pid,euser,args:100 --sort %mem | grep -v grep | grep -i \$@ | awk '{printf \$1/1024 \"MB\"; \$1=\"\"; print }'
}" >> ~/.bashrc
