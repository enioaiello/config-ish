#!/bin/sh
set -e

# Efface le contenu du terminal
clear

# Affichage de l'en-tête
echo "Configuration d'iSH"

# Tente de récupérer le nombre de colonnes, sinon 60 par défaut
if [ -t 1 ]; then
    cols=$(stty size 2>/dev/null | awk '{print $2}')
else
    cols=60
fi
[ -z "$cols" ] && cols=60

# Affiche une ligne de séparation
printf '%*s\n' "$cols" '' | tr ' ' '='

echo "[*] Ajout de dépôts supplémentaires"
ALPINE_VER="$(cut -d. -f1,2 /etc/alpine-release)"
REPO_MAIN="http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/main"
REPO_COMM="http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/community"
REPO_EDGE="http://dl-cdn.alpinelinux.org/alpine/edge/testing"

# Sauvegarde ancien fichier
cp /etc/apk/repositories /etc/apk/repositories.bak

# Écriture du nouveau fichier de dépôts
cat > /etc/apk/repositories <<EOF
$REPO_MAIN
$REPO_COMM
$REPO_EDGE
EOF

# Met à jour le système
echo "[*] Mise à jour du système"
apk update >/dev/null 2>&1 && apk upgrade >/dev/null 2>&1

# Installe les paquets essentiels
echo "[*] Installation des paquets essentiels"
apk add --no-cache --quiet --no-progress --upgrade zsh nano vim neovim curl wget git openssh htop ncdu python3 build-base neofetch tmux tree nodejs py3-pip ffmpeg >/dev/null 2>&1

# Installe les instructions utiles
apk add --no-cache --quiet --no-progress --upgrade coreutils util-linux bash ncurses busybox-extras grep sed >/dev/null 2>&1

echo "[*] Personnalisation du shell"
# Force l’exécution de zsh au démarrage
if ! grep -q "exec zsh" "$HOME/.profile" 2>/dev/null; then
  { echo 'if [ -t 1 ] && [ -z "$ZSH_VERSION" ]; then exec zsh -l; fi'; } >> "$HOME/.profile"
fi
# Remplace le shell dans /etc/passwd
sed -i 's#/bin/ash#/bin/zsh#' /etc/passwd

# Supprime le message de bienvenue
: > /etc/motd

# Installation de Oh My ZSH
export RUNZSH=no CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1

# Plugins externes pour Oh My Zsh
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins" >/dev/null 2>&1
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" >/dev/null 2>&1
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" >/dev/null 2>&1

# Applique le thème de zsh
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
echo "Bienvenue, tapez 'help' pour l'aide."

# Alias
alias ll='ls -la --color=auto'
alias update='apk update && apk upgrade'
alias python='python3'
alias vi='nvim'
alias v='nvim'

# Aide
help() {
  echo "Aide"

  if [ -t 1 ]; then
    cols=$(stty size 2>/dev/null | awk '{print $2}')
  else
    cols=60
  fi
  [ -z "$cols" ] && cols=60

  printf '%*s\n' "$cols" '' | tr ' ' '='
  
  echo "  ll       -> affiche tous les fichiers et répértoire"
  echo "  update   -> effectue une mise à jour du système"
  echo "  python   -> lance Python 3"
  echo "  v / vi   -> lance neovim"
  echo "  help     -> affiche le message d'aide"
  echo "  serve    -> lance un serveur de développement Web"
}
ZSHRC

# Customise Neofetch
mkdir -p "$HOME/.config/neofetch" >/dev/null 2>&1
cat > "$HOME/.config/neofetch/config.conf" <<'NEO'
# Utilise la pomme au lieu du logo d'Alpine
ascii_distro="macos"
image_backend="ascii"
# Optionnel: limiter la largeur si besoin
# ascii_max_width=32
NEO

# Configure neovim
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

# Installer localtunnel globalement (via npm)
npm install -g localtunnel >/dev/null 2>&1 || true

# Alias ou fonction “serve”
cat << 'EOF' >> ~/.zshrc

# Lance un serveur HTTP local + tunnel vers Safari
serve() {
  # usage : serve [PORT]
  PORT=${1:-8080}
  # Lancer un serveur Python en arrière-plan
  python3 -m http.server "$PORT" 
  pid_http=$!
  # Exposer via localtunnel
  lt --port "$PORT"
  # Après fermeture du tunnel, tuer le serveur Python
  kill "$pid_http"
}

# Met à jour le shell
update() {
    echo "[i] Mise à jour du shell avec la dernière version du script..."
    TMPFILE=$(mktemp)
    wget -qO "$TMPFILE" https://raw.githubusercontent.com/enioaiello/config-ish/main/src/setup.sh || {
        echo "[!] Échec du téléchargement de la mise à jour."
        rm -f "$TMPFILE"
        return 1
    }
    chmod +x "$TMPFILE"
    sh "$TMPFILE"
    rm -f "$TMPFILE"
    echo "[✓] Mise à jour terminée. Pour appliquer les changements, redémarrez iSH."
}

EOF

echo "[✓] Installation terminée. Pour appliquer les changements, redémarrez iSH."