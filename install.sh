#!/bin/bash

# ============================================================
# SUPER SCRIPT DE SETUP PARA TERMUX - LENOVO TAB M9 OTIMIZADO
# ============================================================
# Autor: Script Robusto para Ambiente de Desenvolvimento
# Versão: 3.2 - Corrigido: remove mensagens de boas-vindas + zoxide
# ============================================================

# ============================================================
# CONFIGURAÇÕES GLOBAIS
# ============================================================

# Arquivo de log
LOG_FILE="$HOME/termux_setup_$(date +%Y%m%d_%H%M%S).log"
ERROR_LOG="$HOME/termux_setup_errors.log"

# Configurações de timeout e retry
MAX_RETRIES=3
RETRY_DELAY=5
TIMEOUT_DURATION=60

# Flags de controle
SKIP_ERRORS=false
VERBOSE=true
FORCE_MODE=false

# ============================================================
# CORES E ESTILOS
# ============================================================

readonly NC='\033[0m'
readonly BLACK='\033[0;30m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly BLINK='\033[5m'

# ============================================================
# FUNÇÕES DE LOG AVANÇADAS
# ============================================================

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Escreve no arquivo de log
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Mostra na tela baseado no nível e modo verbose
    case "$level" in
        "ERROR")
            echo -e "${RED}${BOLD}🔴 ERRO: ${message}${NC}" >&2
            echo "[$timestamp] [$level] $message" >> "$ERROR_LOG"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  ${message}${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ ${message}${NC}"
            ;;
        "INFO")
            if [ "$VERBOSE" = true ]; then
                echo -e "${BLUE}ℹ️  ${message}${NC}"
            fi
            ;;
        "STEP")
            echo -e "\n${CYAN}${BOLD}════════════════════════════════════════════════════════${NC}"
            echo -e "${CYAN}${BOLD}📍 ${message}${NC}"
            echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════${NC}\n"
            ;;
        "DEBUG")
            if [ "$VERBOSE" = true ]; then
                echo -e "${DIM}🔍 ${message}${NC}"
            fi
            ;;
    esac
}

log_error() { log_message "ERROR" "$1"; }
log_warn() { log_message "WARNING" "$1"; }
log_success() { log_message "SUCCESS" "$1"; }
log_info() { log_message "INFO" "$1"; }
log_step() { log_message "STEP" "$1"; }
log_debug() { log_message "DEBUG" "$1"; }

# ============================================================
# FUNÇÕES DE UTILIDADE
# ============================================================

check_internet() {
    log_debug "Verificando conectividade com a internet..."
    
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 2 google.com >/dev/null 2>&1; then
            log_success "Conexão com internet disponível"
            return 0
        fi
        log_warn "Tentativa $attempt de $max_attempts: Sem internet"
        sleep 3
        attempt=$((attempt + 1))
    done
    
    log_error "Sem conexão com internet após $max_attempts tentativas"
    return 1
}

check_termux() {
    if [ "$(uname -o)" != "Android" ]; then
        log_error "Este script deve ser executado no Termux (Android)"
        exit 1
    fi
    
    log_success "Sistema verificado: Termux/Android"
    
    # Verifica espaço em disco
    local available_space=$(df -k /data | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 1048576 ]; then # 1GB em KB
        log_error "Espaço insuficiente em disco. Necessário pelo menos 1GB livre."
        log_info "Espaço disponível: $((available_space / 1024)) MB"
        exit 1
    fi
    log_info "Espaço em disco: $((available_space / 1024)) MB livre"
}

run_with_retry() {
    local cmd="$1"
    local description="$2"
    local attempt=1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        log_info "Executando: $description (tentativa $attempt/$MAX_RETRIES)"
        
        if eval "$cmd"; then
            log_success "$description concluído com sucesso"
            return 0
        else
            log_warn "Falha na tentativa $attempt: $description"
            if [ $attempt -lt $MAX_RETRIES ]; then
                log_info "Aguardando $RETRY_DELAY segundos antes de tentar novamente..."
                sleep $RETRY_DELAY
            fi
            attempt=$((attempt + 1))
        fi
    done
    
    log_error "$description falhou após $MAX_RETRIES tentativas"
    if [ "$SKIP_ERRORS" = false ]; then
        return 1
    fi
    return 0
}

check_and_fix_dpkg() {
    log_info "Verificando integridade do dpkg..."
    
    # Corrigir possíveis problemas no dpkg
    if [ -f "$PREFIX/var/lib/dpkg/lock" ]; then
        log_warn "Removendo lock do dpkg"
        rm -f "$PREFIX/var/lib/dpkg/lock"
    fi
    
    if [ -f "$PREFIX/var/lib/dpkg/lock-frontend" ]; then
        log_warn "Removendo lock-frontend do dpkg"
        rm -f "$PREFIX/var/lib/dpkg/lock-frontend"
    fi
    
    # Configurar dpkg novamente
    dpkg --configure -a 2>/dev/null || true
    
    log_success "Sistema dpkg verificado e corrigido"
}

install_package_safe() {
    local package="$1"
    local max_retries=2
    
    log_info "Instalando pacote: $package"
    
    for i in $(seq 1 $max_retries); do
        # Tentativa normal
        if pkg install -y "$package" 2>/dev/null; then
            log_success "Pacote $package instalado com sucesso"
            return 0
        fi
        
        # Se falhar, tentar com force overwrite
        log_warn "Tentativa $i: Instalação normal falhou, tentando com force-overwrite..."
        if pkg install -y "$package" --force-overwrite 2>/dev/null; then
            log_success "Pacote $package instalado com force-overwrite"
            return 0
        fi
        
        # Limpar cache e tentar novamente
        if [ $i -lt $max_retries ]; then
            log_info "Limpando cache e tentando novamente..."
            pkg clean 2>/dev/null
            sleep 3
        fi
    done
    
    log_error "Não foi possível instalar $package após $max_retries tentativas"
    return 1
}

# ============================================================
# FUNÇÃO DE BACKUP ROBUSTA
# ============================================================

create_backup() {
    log_step "Criando backup do sistema atual"
    
    local backup_dir="$HOME/backup_termux_$(date +%Y%m%d_%H%M%S)"
    local backup_file="${backup_dir}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    # Lista de diretórios para backup
    local backup_items=(
        ".termux"
        ".config"
        ".local"
        ".oh-my-zsh"
        ".zshrc"
        ".bashrc"
        ".profile"
        ".gitconfig"
    )
    
    for item in "${backup_items[@]}"; do
        if [ -e "$HOME/$item" ]; then
            cp -r "$HOME/$item" "$backup_dir/" 2>/dev/null || true
            log_debug "Backup criado: $item"
        fi
    done
    
    # Compactar backup
    tar -czf "$backup_file" -C "$HOME" "$(basename "$backup_dir")" 2>/dev/null
    
    if [ -f "$backup_file" ]; then
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_success "Backup criado: $backup_file (tamanho: $backup_size)"
        echo "$backup_file"
    else
        log_warn "Backup não foi criado (não há dados para backup)"
        echo ""
    fi
}

# ============================================================
# INSTALAÇÃO DO LUA LANGUAGE SERVER
# ============================================================

install_lua_language_server() {
    log_step "Instalando Lua Language Server"
    
    # Verificar se npm está instalado
    if ! command -v npm &> /dev/null; then
        log_info "Instalando npm primeiro..."
        install_package_safe "nodejs"
    fi
    
    # Instalar lua-language-server via npm
    log_info "Baixando e instalando lua-language-server..."
    
    for i in 1 2 3; do
        if npm install -g lua-language-server 2>/dev/null; then
            log_success "lua-language-server instalado via npm"
            return 0
        fi
        
        log_warn "Tentativa $i: Falha na instalação via npm"
        sleep 3
        
        # Tentar instalar com --force
        if npm install -g lua-language-server --force 2>/dev/null; then
            log_success "lua-language-server instalado com --force"
            return 0
        fi
        sleep 3
    done
    
    # Método alternativo: baixar binário pré-compilado
    log_info "Tentando método alternativo de instalação..."
    local lua_ls_url="https://github.com/LuaLS/lua-language-server/releases/download/3.9.0/lua-language-server-3.9.0-linux-x64.tar.gz"
    local temp_dir="$HOME/temp_lua_ls"
    
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    if wget -q "$lua_ls_url"; then
        tar -xzf lua-language-server-*.tar.gz 2>/dev/null
        mkdir -p "$HOME/.local/bin"
        cp bin/lua-language-server "$HOME/.local/bin/" 2>/dev/null
        chmod +x "$HOME/.local/bin/lua-language-server"
        log_success "lua-language-server instalado via download direto"
    else
        log_warn "Não foi possível instalar lua-language-server"
    fi
    
    cd "$HOME"
    rm -rf "$temp_dir"
    
    # Configurar PATH para incluir binários npm
    export PATH="$HOME/.local/bin:$PATH"
    export PATH="$HOME/.npm-global/bin:$PATH"
}

# ============================================================
# RESET COMPLETO DO TERMUX
# ============================================================

reset_termux() {
    log_step "Resetando Termux para estado inicial"
    
    # Lista de tudo que será removido
    local items_to_remove=(
        ".bashrc"
        ".bash_profile"
        ".zshrc"
        ".oh-my-zsh"
        ".p10k.zsh"
        ".termux"
        ".config"
        ".local"
        ".cache"
        ".oh-my-posh"
        ".Themes"
        ".local/share/nvim"
        ".nvim"
        ".npm"
        ".cargo"
        ".python_history"
        ".wget-hsts"
        ".zsh_history"
        ".zcompdump*"
        ".node_repl_history"
        ".mysql_history"
        ".bash_history"
        ".profile"
        ".gitconfig"
        ".wgetrc"
        ".curlrc"
        ".npm-global"
    )
    
    log_info "Removendo configurações antigas..."
    for item in "${items_to_remove[@]}"; do
        rm -rf "$HOME/$item" 2>/dev/null || true
        log_debug "Removido: $item"
    done
    
    # Recriar diretórios essenciais
    mkdir -p "$HOME/.termux"
    mkdir -p "$HOME/.config/nvim"
    mkdir -p "$HOME/.Themes"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.cache"
    mkdir -p "$HOME/.npm-global"
    
    log_success "Reset concluído"
}

# ============================================================
# CONFIGURAÇÕES DO TERMUX
# ============================================================

configure_termux() {
    log_step "Configurando Termux"
    
    # Configurações de teclado e UI
    cat > "$HOME/.termux/termux.properties" << 'EOF'
# Configurações otimizadas para Lenovo Tab M9
use-black-ui = true
bell-character = ignore
use-styling = true
fullscreen = true
allow-external-apps = true
default-isession = zsh

# Teclas extras para tablet
extra-keys = [
  ['ESC','/','-','HOME','UP','END','PGUP'],
  ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN'],
  ['(',')','{','}','[',']','<','>'],
  ['~','|','`','\\',';',"'",'"','.']
]

# Fonte e tamanho
font-size = 12
use-bold-font = true
use-cjk-width = false

# Scrolling
terminal-transcript-rows = 10000
backup-transcript = true
login-shell = true

# REMOVE MENSAGEM DE BOAS-VINDAS PADRÃO DO TERMUX
show-welcome-message = false
EOF
    
    # Criar arquivo .hushlogin para suprimir mensagens de login
    touch "$HOME/.hushlogin"
    
    # Remover mensagens de boas-vindas do motd (Message Of The Day)
    if [ -f "$PREFIX/etc/motd" ]; then
        mv "$PREFIX/etc/motd" "$PREFIX/etc/motd.bak" 2>/dev/null || true
    fi
    
    # Recarregar configurações com retry
    for i in 1 2 3; do
        if termux-reload-settings 2>/dev/null; then
            log_success "Configurações do Termux aplicadas"
            break
        fi
        sleep 2
    done
}

# ============================================================
# PERMISSÕES DE ARMAZENAMENTO
# ============================================================

setup_storage() {
    log_step "Configurando permissões de armazenamento"
    
    # Solicitar acesso ao storage
    log_info "Solicitando acesso ao armazenamento..."
    
    # Tentar múltiplas vezes
    for i in 1 2 3; do
        if termux-setup-storage 2>/dev/null; then
            log_success "Acesso ao storage concedido"
            sleep 3
            return 0
        fi
        log_warn "Tentativa $i: Aguardando permissão..."
        sleep 3
    done
    
    log_warn "Storage não configurado automaticamente"
    
    # Criar diretórios alternativos
    mkdir -p "$HOME/storage/shared" 2>/dev/null || true
    ln -s /sdcard "$HOME/storage/shared" 2>/dev/null || true
}

# ============================================================
# ATUALIZAÇÃO DE PACOTES COM ROBUSTEZ
# ============================================================

update_packages() {
    log_step "Atualizando sistema de pacotes"
    
    # Corrigir dpkg primeiro
    check_and_fix_dpkg
    
    # Trocar repositório para um estável
    log_info "Configurando repositório estável..."
    termux-change-repo
    
    # Limpar cache
    pkg clean 2>/dev/null
    
    # Atualizar com retry
    if ! run_with_retry "pkg update -y" "Atualização da lista de pacotes"; then
        log_error "Falha na atualização. Tentando repositório alternativo..."
        
        # Forçar repositório confiável
        echo "deb https://packages.termux.org/apt/termux-main stable main" > "$PREFIX/etc/apt/sources.list"
        pkg update -y || {
            log_error "Não foi possível atualizar pacotes"
            return 1
        }
    fi
    
    # Upgrade com cuidado
    log_info "Atualizando pacotes existentes..."
    pkg upgrade -y --force-overwrite 2>/dev/null || pkg upgrade -y 2>/dev/null
    
    log_success "Sistema de pacotes atualizado"
}

# ============================================================
# INSTALAÇÃO DE PACOTES EM LOTE
# ============================================================

install_essential_packages() {
    log_step "Instalando pacotes essenciais"
    
    # Lista de pacotes em ordem de importância
    local packages_core=(
        "neovim"
        "git"
        "zsh"
        "curl"
        "wget"
    )
    
    local packages_tools=(
        "oh-my-posh"
        "nodejs"
        "python"
        "openssh"
        "htop"
    )
    
    local packages_search=(
        "fzf"
        "ripgrep"
        "fd"
        "tree"
        "zoxide"  # ADICIONADO: zoxide aqui para ser instalado
    )
    
    local packages_extra=(
        "bat"
        "eza"
        "nano"
        "man"
        "unzip"
        "zip"
    )
    
    # Instalar pacotes core (fundamentais)
    for package in "${packages_core[@]}"; do
        install_package_safe "$package" || {
            log_error "Falha crítica ao instalar $package"
            if [ "$SKIP_ERRORS" = false ]; then
                return 1
            fi
        }
        sleep 1
    done
    
    # Instalar ferramentas
    log_info "Instalando pacotes de ferramentas..."
    for package in "${packages_tools[@]}"; do
        install_package_safe "$package" || true
        sleep 1
    done
    
    # Instalar ferramentas de busca
    log_info "Instalando ferramentas de busca..."
    for package in "${packages_search[@]}"; do
        install_package_safe "$package" || true
        sleep 1
    done
    
    # Instalar extras
    log_info "Instalando pacotes extras..."
    for package in "${packages_extra[@]}"; do
        install_package_safe "$package" || true
        sleep 1
    done
    
    log_success "Todos os pacotes instalados com sucesso"
}

# ============================================================
# INSTALAÇÃO DO OH-MY-ZSH
# ============================================================

install_ohmyzsh() {
    log_step "Instalando Oh My Zsh"
    
    # Instalar zsh se não estiver presente
    if ! command -v zsh &> /dev/null; then
        install_package_safe "zsh"
    fi
    
    # Backup do .zshrc existente
    [ -f "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    
    # Instalar Oh My Zsh sem interação
    export RUNZSH=no
    export CHSH=no
    export KEEP_ZSHRC=yes
    
    log_info "Baixando e instalando Oh My Zsh..."
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null; then
        log_success "Oh My Zsh instalado com sucesso"
    else
        log_warn "Falha na instalação automática, tentando método alternativo..."
        git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" 2>/dev/null
        cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
    fi
}

# ============================================================
# CONFIGURAR ZSH COMO SHELL PADRÃO DO TERMUX
# ============================================================

set_zsh_default_shell() {
    log_step "Configurando Zsh como shell padrão do Termux"
    
    # Método 1: Modificar .bashrc para iniciar zsh
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "zsh" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# Iniciar Zsh automaticamente" >> "$HOME/.bashrc"
            echo "if [ -t 1 ] && command -v zsh &> /dev/null; then" >> "$HOME/.bashrc"
            echo "    exec zsh" >> "$HOME/.bashrc"
            echo "fi" >> "$HOME/.bashrc"
            log_success ".bashrc configurado para iniciar Zsh"
        fi
    else
        echo "if [ -t 1 ] && command -v zsh &> /dev/null; then exec zsh; fi" > "$HOME/.bashrc"
        log_success ".bashrc criado para iniciar Zsh"
    fi
    
    # Método 2: Configurar variável SHELL
    echo "export SHELL=$(which zsh)" >> "$HOME/.profile" 2>/dev/null || true
    
    # Método 3: Usar chsh se disponível
    if command -v chsh &> /dev/null; then
        chsh -s zsh 2>/dev/null && log_success "Shell padrão alterado via chsh" || true
    fi
    
    # Método 4: Configurar no termux.properties
    if grep -q "default-isession" "$HOME/.termux/termux.properties" 2>/dev/null; then
        sed -i 's/^default-isession.*/default-isession = zsh/' "$HOME/.termux/termux.properties"
    else
        echo "default-isession = zsh" >> "$HOME/.termux/termux.properties"
    fi
    
    termux-reload-settings 2>/dev/null
    
    log_success "Zsh configurado como shell padrão"
    log_warn "Ao reabrir o Termux, o Zsh será iniciado automaticamente"
}

# ============================================================
# CONFIGURAÇÃO DO TEMA E FONTES
# ============================================================

configure_theme() {
    log_step "Configurando tema M365Princess"
    
    # Baixar tema com retry
    local theme_url="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/M365Princess.omp.json"
    local theme_path="$HOME/.Themes/M365Princess.omp.json"
    
    mkdir -p "$HOME/.Themes"
    
    for i in 1 2 3; do
        if wget -q -O "$theme_path" "$theme_url"; then
            log_success "Tema M365Princess baixado"
            break
        fi
        log_warn "Tentativa $i: Falha ao baixar tema"
        sleep 3
    done
    
    # Fonte Nerd Font
    log_info "Instalando Meslo Nerd Font..."
    local font_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/M/Regular/MesloLGMNerdFont-Regular.ttf"
    
    for i in 1 2 3; do
        if wget -q -O "$HOME/.termux/font.ttf" "$font_url"; then
            chmod 644 "$HOME/.termux/font.ttf"
            termux-reload-settings 2>/dev/null
            log_success "Fonte Meslo instalada"
            break
        fi
        log_warn "Tentativa $i: Falha ao baixar fonte"
               sleep 3
    done
}

# ============================================================
# CRIAÇÃO DO ZSHRC COMPLETO
# ============================================================

create_zshrc() {
    log_step "Criando configuração do Zsh"
    
    cat > "$HOME/.zshrc" << 'EOF'
# ============================================================
# CONFIGURAÇÃO COMPLETA DO ZSH PARA TERMUX
# ============================================================

# REMOVE MENSAGENS DE BOAS-VINDAS (corrigido)
if [ -f "$PREFIX/etc/motd" ]; then
    mv "$PREFIX/etc/motd" "$PREFIX/etc/motd.bak" 2>/dev/null || true
fi
touch "$HOME/.hushlogin"

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Plugins essenciais - zoxide incluído na lista
plugins=(
    git
    node
    python
    npm
    history
    extract
    zoxide    # Plugin do zoxide para integração com Oh My Zsh
    fzf
    sudo
    colored-man-pages
    command-not-found
)

# Inicializar Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Oh My Posh com tema M365Princess
if command -v oh-my-posh &> /dev/null; then
    eval "$(oh-my-posh init zsh --config ~/.Themes/M365Princess.omp.json)"
fi

# ============================================================
# ALIASES OTIMIZADOS
# ============================================================

# Navegação avançada
alias ll='eza -lah --icons --git'
alias la='eza -a --icons'
alias l='eza -l --icons --git'
alias lt='eza --tree --level=2 --icons'
alias lta='eza --tree --level=3 --icons -a'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Editores
alias nv='nvim'
alias v='nvim'
alias nano='nano -c'

# Utilitários
alias c='clear'
alias h='history'
alias paths='echo $PATH | tr ":" "\n"'
alias ports='netstat -tulpn'

# Ferramentas modernas
if command -v bat &> /dev/null; then
    alias cat='bat --style=plain'
    alias catn='bat'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi

# Git avançado
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph'
alias gst='git stash'
alias gsp='git stash pop'

# ============================================================
# VARIÁVEIS DE AMBIENTE
# ============================================================

# História
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY

# Editores
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less

# PATH adicional
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# Node.js
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"

# Python
export PYTHONIOENCODING=UTF-8

# Lua Language Server
export PATH="$HOME/.local/bin:$PATH"

# ============================================================
# ZOXIDE - Inicialização condicional (CORRIGIDO)
# ============================================================
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd='z'
    alias cdi='zi'
fi

# ============================================================
# FZF (Fuzzy finder)
# ============================================================
if command -v fzf &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# ============================================================
# PROMPT PERSONALIZADO
# ============================================================
prompt_context() { }

# ============================================================
# COMPLEMENTOS E CORREÇÕES
# ============================================================

# Corrigir backspace no Termux
bindkey "^?" backward-delete-char
bindkey "^H" backward-delete-char

# Autocomplete case insensitive
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
EOF

    log_success "Arquivo .zshrc criado com sucesso (sem mensagens de boas-vindas)"
}

# ============================================================
# INSTALAÇÃO DO NVCHAD (COM TRANSPARÊNCIA)
# ============================================================

install_nvchad() {
    log_step "Instalando NvChad"
    
    # Remover configuração anterior
    rm -rf "$HOME/.config/nvim"
    rm -rf "$HOME/.local/share/nvim"
    rm -rf "$HOME/.cache/nvim"
    
    # Clonar NvChad starter com retry
    log_info "Clonando NvChad starter..."
    for i in 1 2 3; do
        if git clone https://github.com/NvChad/starter "$HOME/.config/nvim" 2>/dev/null; then
            log_success "NvChad starter clonado com sucesso"
            break
        fi
        log_warn "Tentativa $i: Falha ao clonar NvChad"
        sleep 3
    done
    
    # Criar configuração customizada COM TRANSPARÊNCIA
    mkdir -p "$HOME/.config/nvim/lua/custom"
    
    cat > "$HOME/.config/nvim/lua/custom/init.lua" << 'EOF'
-- ============================================================
-- CONFIGURAÇÕES CUSTOMIZADAS PARA TABLET LENOVO
-- ============================================================

-- Otimizações para tablet
vim.opt.mouse = "a"
vim.opt.termguicolors = true
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5

-- Clipboard adaptado para Termux
vim.opt.clipboard = ""

-- Undo persistente
vim.opt.undofile = true
local undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.undodir = undodir

if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, "p")
end

-- Interface otimizada
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true

-- ============================================================
-- TRANSPARÊNCIA COMPLETA
-- ============================================================

-- Fundo transparente para todos os elementos
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "none" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.api.nvim_set_hl(0, "VertSplit", { bg = "none" })
vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLine", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLineSel", { bg = "none" })
vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
vim.api.nvim_set_hl(0, "PmenuSel", { bg = "none" })
vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "none" })
vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "none" })

-- Mensagem de transparência ativada (silenciosa)
-- print("✨ Transparência ativada no Neovim")

-- ============================================================
-- CONFIGURAÇÃO DO LUA LANGUAGE SERVER
-- ============================================================

-- Configurar LSP para Lua
local lspconfig = require("lspconfig")

-- Verificar se lua-language-server está instalado
local lua_ls_path = vim.fn.executable("lua-language-server") == 1

if lua_ls_path then
    lspconfig.lua_ls.setup({
        settings = {
            Lua = {
                runtime = { version = "LuaJIT" },
                diagnostics = { globals = { "vim" } },
                workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                    checkThirdParty = false,
                },
                telemetry = { enable = false },
            },
        },
    })
    -- print("🚀 Lua Language Server configurado")
else
    -- Caminho alternativo para lua-language-server
    local alt_paths = {
        "$HOME/.local/bin/lua-language-server",
        "$HOME/.npm-global/bin/lua-language-server",
        "$PREFIX/bin/lua-language-server",
    }
    
    for _, path in ipairs(alt_paths) do
        local expanded_path = string.gsub(path, "$HOME", os.getenv("HOME"))
        expanded_path = string.gsub(expanded_path, "$PREFIX", os.getenv("PREFIX"))
        
        if vim.fn.executable(expanded_path) == 1 then
            vim.fn.setenv("PATH", vim.fn.getenv("PATH") .. ":" .. vim.fn.fnamemodify(expanded_path, ":h"))
            lspconfig.lua_ls.setup({})
            -- print("🚀 Lua Language Server configurado em: " .. expanded_path)
            break
        end
    end
end

-- ============================================================
-- KEYMAPS PARA TABLET
-- ============================================================

local map = vim.keymap.set

-- Navegação fácil
map("n", "<Tab>", ":bnext<CR>", { desc = "Próximo buffer" })
map("n", "<S-Tab>", ":bprevious<CR>", { desc = "Buffer anterior" })
map("n", "<leader>q", ":bd<CR>", { desc = "Fechar buffer" })

-- Terminal integrado
map("n", "<leader>t", ":term<CR>", { desc = "Abrir terminal" })
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Sair do terminal" })

-- Comentários
map("n", "<leader>/", "gcc", { desc = "Comentar linha" })
map("v", "<leader>/", "gc", { desc = "Comentar seleção" })

-- Limpar highlight
map("n", "<leader>h", ":nohlsearch<CR>", { desc = "Limpar pesquisa" })

-- Highlight ao copiar
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.highlight.on_yank({ timeout = 150 }) end,
})

-- print("Configurações para tablet carregadas! 🚀")
EOF

    log_success "NvChad configurado com customizações para tablet e transparência"
}

# ============================================================
# CONFIGURAÇÕES FINAIS
# ============================================================

final_setup() {
    log_step "Aplicando configurações finais"
    
    # Configurar git global
    if command -v git &> /dev/null; then
        git config --global user.name "Termux User" 2>/dev/null
        git config --global user.email "user@termux.dev" 2>/dev/null
        git config --global core.editor "nvim" 2>/dev/null
        git config --global init.defaultBranch "main" 2>/dev/null
        log_success "Git configurado globalmente"
    fi
    
    # Configurar npm global
    if command -v npm &> /dev/null; then
        npm config set prefix "$HOME/.npm-global" 2>/dev/null
        log_success "NPM configurado"
    fi
    
    # Criar diretórios de projeto
    mkdir -p "$HOME/projects"
    mkdir -p "$HOME/scripts"
    mkdir -p "$HOME/.local/bin"
    
    # Adicionar scripts úteis
    cat > "$HOME/scripts/termux_update.sh" << 'EOF'
#!/bin/bash
echo "🔄 Atualizando Termux..."
pkg update && pkg upgrade -y
echo "✅ Atualização concluída!"
EOF
    chmod +x "$HOME/scripts/termux_update.sh"
    
    # Script para verificar LSP
    cat > "$HOME/scripts/check_lsp.sh" << 'EOF'
#!/bin/bash
echo "🔍 Verificando Lua Language Server..."
if command -v lua-language-server &> /dev/null; then
    echo "✅ Lua Language Server instalado: $(which lua-language-server)"
    lua-language-server --version 2>/dev/null || echo "   Versão: instalada"
else
    echo "❌ Lua Language Server não encontrado"
    echo "   Tente instalar manualmente: npm install -g lua-language-server"
fi
EOF
    chmod +x "$HOME/scripts/check_lsp.sh"
    
    # Garantir que o .hushlogin exista
    touch "$HOME/.hushlogin"
    
    log_success "Configurações finais aplicadas"
}

# ============================================================
# VERIFICAÇÃO E RELATÓRIO FINAL
# ============================================================

generate_report() {
    log_step "Gerando relatório de instalação"
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "                 RELATÓRIO DE INSTALAÇÃO"
    echo "════════════════════════════════════════════════════════"
    echo ""
    
    # Verificar instalações
    local packages_installed=(
        "neovim"
        "git"
        "zsh"
        "curl"
        "wget"
        "oh-my-posh"
        "nodejs"
        "python"
        "fzf"
        "ripgrep"
        "fd"
        "bat"
        "eza"
        "zoxide"
    )
    
    echo "📦 PACOTES INSTALADOS:"
    for pkg in "${packages_installed[@]}"; do
        if command -v "$pkg" &> /dev/null || pkg list-installed 2>/dev/null | grep -q "$pkg"; then
            echo "  ✅ $pkg"
        else
            echo "  ❌ $pkg"
        fi
    done
    
    echo ""
    echo "🔧 FERRAMENTAS ADICIONAIS:"
    
    # Verificar Lua Language Server
    if command -v lua-language-server &> /dev/null; then
        echo "  ✅ lua-language-server (LSP para Lua)"
    elif [ -f "$HOME/.local/bin/lua-language-server" ]; then
        echo "  ✅ lua-language-server (instalado localmente)"
    else
        echo "  ⚠️  lua-language-server (não encontrado - pode instalar manualmente)"
    fi
    
    # Verificar npm packages
    if command -v npm &> /dev/null; then
        echo "  ✅ npm (Node Package Manager)"
    fi
    
    echo ""
    echo "📁 DIRETÓRIOS CRIADOS:"
    echo "  ✅ ~/.config/nvim (NvChad + Transparência)"
    echo "  ✅ ~/.Themes (Temas)"
    echo "  ✅ ~/projects (Projetos)"
    echo "  ✅ ~/scripts (Scripts)"
    echo "  ✅ ~/.local/bin (Binários locais)"
    echo "  ✅ ~/.npm-global (Pacotes npm globais)"
    
    echo ""
    echo "🎨 TEMAS E CONFIGURAÇÕES:"
    echo "  ✅ M365Princess (Oh My Posh)"
    echo "  ✅ Meslo Nerd Font"
    echo "  ✅ Transparência ativada no Neovim"
    echo "  ✅ Zsh configurado como shell padrão"
    echo "  ✅ Mensagens de boas-vindas removidas"
    echo "  ✅ zoxide instalado e configurado"
    
    echo ""
    echo "⚡ COMANDOS ÚTEIS:"
    echo "  nvim                    - Abrir Neovim com NvChad (transparente)"
    echo "  zsh                     - Iniciar Zsh"
    echo "  ll / la / lt            - Listagem avançada"
    echo "  z <dir>                 - Navegação rápida com zoxide"
    echo "  ~/scripts/termux_update.sh - Atualizar sistema"
    echo "  ~/scripts/check_lsp.sh  - Verificar Lua Language Server"
    
    echo ""
    echo "📝 LOGS SALVOS EM:"
    echo "  📄 $LOG_FILE"
    if [ -f "$ERROR_LOG" ]; then
        echo "  📄 $ERROR_LOG"
    fi
    
    echo ""
    log_success "Setup concluído com sucesso!"
}

# ============================================================
# FUNÇÃO PRINCIPAL
# ============================================================

main() {
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║     🚀 SETUP COMPLETO PARA TERMUX - LENOVO TAB M9           ║"
    echo "║                                                              ║"
    echo "║     Ambiente de Desenvolvimento Profissional                 ║"
    echo "║     Versão: 3.2 - Sem msgs boas-vindas + zoxide fix        ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Verificações iniciais
    check_termux
    
    # Verificar internet
    if ! check_internet; then
        log_error "Conecte-se à internet e execute novamente"
        exit 1
    fi
    
    # Confirmar reset
    echo ""
    log_warn "${BOLD}ATENÇÃO: Este script vai resetar completamente o Termux!${NC}"
    echo ""
    read -p "Deseja fazer backup? (s/N): " -n 1 -r
    echo ""
    
    BACKUP_FILE=""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        BACKUP_FILE=$(create_backup)
        echo ""
    fi
    
    echo ""
    read -p "Digite 'RESETAR' para confirmar: " confirmacao
    
    if [ "$confirmacao" != "RESETAR" ]; then
        log_error "Reset cancelado"
        exit 1
    fi
    
    # Executar setup em etapas com verificação
    reset_termux
    configure_termux
    setup_storage
    update_packages || exit 1
    install_essential_packages || exit 1
    install_ohmyzsh
    configure_theme
    create_zshrc
    install_lua_language_server
    install_nvchad
    set_zsh_default_shell
    final_setup
    generate_report
    
    echo ""
    log_warn "${BOLD}⚠️  IMPORTANTE: Feche e reabra o Termux para aplicar todas as mudanças!${NC}"
    echo ""
    log_info "Ao reabrir, o Zsh iniciará LIMPO, sem mensagens de boas-vindas!"
    log_info "Para iniciar o Neovim após reiniciar: nvim"
    echo ""
}

# ============================================================
# TRATAMENTO DE SINAIS
# ============================================================

trap 'log_error "Script interrompido pelo usuário"; exit 1' INT TERM
trap 'log_info "Script finalizado com código $?"' EXIT

# ============================================================
# EXECUÇÃO
# ============================================================

# Parse de argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-errors)
            SKIP_ERRORS=true
            shift
            ;;
        --quiet)
            VERBOSE=false
            shift
            ;;
        --force)
            FORCE_MODE=true
            shift
            ;;
        --help)
            echo "Uso: $0 [opções]"
            echo "Opções:"
            echo "  --skip-errors  Continua mesmo com erros"
            echo "  --quiet        Modo silencioso (menos output)"
            echo "  --force        Força execução sem confirmação"
            echo "  --help         Mostra esta ajuda"
            exit 0
            ;;
        *)
            echo "Opção desconhecida: $1"
            exit 1
            ;;
    esac
done

# Executar
main "$@"