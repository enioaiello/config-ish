#!/bin/sh
set -e

echo "[*] Mise à jour du système"
apk update >/dev/null 2>&1 && apk upgrade >/dev/null 2>&1

echo "[*] Installation des paquets essentiels"
apk add zsh nano vim neovim curl wget git openssh htop ncdu python3 build-base neofetch tmux tree nodejs py3-pip ffmpeg >/dev/null 2>&1

echo "[*] Définition de zsh comme shell par défaut"
# 1) Forcer l’exec zsh au démarrage iSH (fiable dans iSH)
if ! grep -q "exec zsh" "$HOME/.profile" 2>/dev/null; then
  { echo 'if [ -t 1 ] && [ -z "$ZSH_VERSION" ]; then exec zsh -l; fi'; } >> "$HOME/.profile"
fi
# 2) Remplacer le shell dans /etc/passwd (au cas où iSH le respecte)
sed -i 's#/bin/ash#/bin/zsh#' /etc/passwd

echo "[*] Suppression du message de bienvenue"
: > /etc/motd

echo "[*] Installation de Oh My Zsh"
export RUNZSH=no CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1

echo "[*] Installation des plugins Oh My Zsh"
# Plugins externes pour Oh My Zsh
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins" >/dev/null 2>&1
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" >/dev/null 2>&1
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" >/dev/null 2>&1

echo "[*] Configuration de Zsh"
cat > "$HOME/.zshrc" <<'ZSHRC'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"

# Plugins Oh My Zsh (laisser syntax-highlighting en dernier)
plugins=(
  git
  z
  sudo
  command-not-found
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# Améliorations de complétion / navigation
autoload -Uz compinit && compinit
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
CASE_SENSITIVE="false"
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000

# Couleur des autosuggestions plus discrète
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Message d'accueil minimal
echo "Tapez 'help' pour l'aide."

# Alias
alias ll='ls -la --color=auto'
alias update='apk update && apk upgrade'
alias python='python3'
alias vi='nvim'
alias v='nvim'

# Aide
help() {
  echo "[*] Commandes utiles :"
  echo "  ll       -> affiche tous les fichiers et répértoire"
  echo "  update   -> effectue une mise à jour du système"
  echo "  python   -> lance Python 3"
  echo "  v / vi   -> lance neovim"
  echo "  help     -> affiche le message d'aide"
}
ZSHRC

echo "[*] Customosation de Neofetch"
mkdir -p "$HOME/.config/neofetch" >/dev/null 2>&1
cat > "$HOME/.config/neofetch/config.conf" <<'NEO'
# Utiliser la pomme et laisser l'affichage par défaut de neofetch
ascii_distro="macos"
image_backend="ascii"
# Optionnel: limiter la largeur si besoin
# ascii_max_width=32
NEO

echo "[*] Configuration de Neovim"
# Gestionnaire de plugins (vim-plug)
curl -fsSL -o "$HOME/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim >/dev/null 2>&1

mkdir -p "$HOME/.config/nvim" >/dev/null 2>&1
cat > "$HOME/.config/nvim/init.vim" <<'NVIM'
" --- Plugins via vim-plug ---
call plug#begin('~/.local/share/nvim/plugged')
Plug 'preservim/nerdtree'          " Explorateur
Plug 'itchyny/lightline.vim'       " Barre de statut
Plug 'tpope/vim-commentary'        " Commentaires
Plug 'jiangmiao/auto-pairs'        " Parenthèses auto
Plug 'tomasiser/vim-code-dark'     " Thème VS Code Dark
call plug#end()

" --- Apparence / confort ---
set number relativenumber
set tabstop=4 shiftwidth=4 expandtab
set autoindent smartindent
set cursorline
set termguicolors
colorscheme codedark

" Ouvrir l'explorateur au lancement si aucun fichier donné
augroup ish_start
  autocmd!
  autocmd VimEnter * if argc() == 0 | NERDTree | wincmd p | endif
augroup END

" Raccourcis
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-s> :w<CR>
NVIM

# Installer les plugins Neovim silencieusement
nvim +PlugInstall +qall >/dev/null 2>&1 || true

echo "[*] Terminé."
echo "➡ Afin que les changements soient pris en compte, redémarrez iSH."
