#!/bin/sh
set -e

echo "[*] Mise à jour du système..."
apk update && apk upgrade

echo "[*] Installation des paquets essentiels..."
apk add zsh nano neovim curl wget git openssh htop ncdu python3 py3-pip build-base neofetch tmux nodejs npm tree

echo "[*] Installer code-server (VS Code dans le navigateur)..."
npm install -g code-server

echo "[*] Définir Zsh comme shell par défaut..."
echo /bin/zsh > ~/.shell

echo "[*] Vider le fichier de bienvenue..."
: > /etc/motd

echo "[*] Installation de Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
fi
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

echo "[*] Configuration du thème Oh My Zsh (agnoster)..."
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc

echo "[*] Ajout d’alias pratiques et de la commande d’aide..."
cat >> ~/.zshrc << 'EOF'

# --- Alias personnalisés ---
alias ll='ls -lh --color=auto'
alias la='ls -lha --color=auto'
alias tree='tree -C'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias gp='git pull'
alias gpu='git push'
alias v='nvim'
alias n='nano'
alias vscode='code-server --bind-addr 127.0.0.1:8080'

# Mise à jour complète avec nettoyage
alias update-all='apk update && apk upgrade && pip install --upgrade pip setuptools && npm update -g && apk cache clean'

# Commande d’aide personnalisée
helpme() {
    echo ""
    echo "==================== AIDE iSH ===================="
    echo " Commandes utiles :"
    echo "   ll        -> ls -lh"
    echo "   la        -> ls -lha"
    echo "   tree      -> afficher l'arborescence des dossiers"
    echo "   ..        -> remonter d’un dossier"
    echo "   ...       -> remonter de deux dossiers"
    echo "   gs        -> git status"
    echo "   gp        -> git pull"
    echo "   gpu       -> git push"
    echo "   v         -> lancer Neovim (style VS Code)"
    echo "   n         -> lancer nano"
    echo "   vscode    -> lancer VS Code dans Safari (localhost:8080)"
    echo ""
    echo " Gestion :"
    echo "   update-all -> met à jour apk, pip, npm et nettoie le cache"
    echo "   helpme     -> affiche ce guide"
    echo "=================================================="
    echo ""
}
EOF

echo "[*] Configuration de Neofetch..."
mkdir -p ~/.config/neofetch
cat > ~/.config/neofetch/config.conf << 'EOF'
print_info() {
    info title
    info underline
    info "OS" distro
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "Terminal" term
    info "CPU" cpu
    info "Memory" memory
}

ascii_distro="macos"
EOF

echo "[*] Configuration de Neovim façon VS Code ++ ..."
mkdir -p ~/.config/nvim

# Installer vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

cat > ~/.config/nvim/init.vim << 'EOF'
" --- Neovim façon VS Code ---
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent
set cursorline
set termguicolors
set background=dark
set laststatus=2
syntax on

" --- Gestionnaire de plugins ---
call plug#begin('~/.config/nvim/plugged')

" Thème VS Code
Plug 'folke/tokyonight.nvim'

" Barre d’état moderne
Plug 'nvim-lualine/lualine.nvim'

" Explorateur de fichiers
Plug 'nvim-tree/nvim-tree.lua'

" Treesitter (meilleure coloration syntaxique)
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Autocomplétion
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'neovim/nvim-lspconfig'

call plug#end()

" --- Config Plugins ---
colorscheme tokyonight

lua << EOF
require('lualine').setup { options = { theme = 'tokyonight' } }
require('nvim-tree').setup {}
EOF

" --- Raccourcis type VS Code ---
nmap <C-s> :w<CR>
nmap <C-q> :q<CR>
nmap <C-c> :noh<CR>
nmap <C-n> :NvimTreeToggle<CR>
EOF

echo "[✔] Installation terminée !"
echo "Lance 'nvim' puis ':PlugInstall' pour installer les plugins"
echo "Lance 'vscode' pour ouvrir VS Code dans Safari à http://127.0.0.1:8080"
