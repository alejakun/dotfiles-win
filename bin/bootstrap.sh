#!/bin/bash

# ============================================================================
# bootstrap.sh - Arranque de una Mac nueva
# ============================================================================
# Uso:
#   bash <(curl -fsSL https://raw.githubusercontent.com/alejakun/dotfiles-bootstrap/main/bin/bootstrap.sh)
#
# Instala lo mínimo para poder clonar el repositorio privado de dotfiles y le
# entrega el control a su instalador. Todo lo demás vive allá: paquetes,
# symlinks, configuración de git, shells y logging.
#
# El orden importa. GitHub CLI se autentica por navegador una sola vez, y con
# ese token registra la llave SSH de este equipo. A partir de ahí todo es SSH,
# incluido el primer clon: HTTPS nunca se usa como transporte de git.
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

DOTFILES_DIR="$HOME/.dotfiles"

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step()    { echo -e "${YELLOW}▸${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }
print_info()    { echo -e "${CYAN}ℹ${NC} $1"; }

print_header "🚀 Dotfiles Bootstrap"

# ============================================================================
# 1. Guardia de plataforma
# ============================================================================

if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "Este script solo funciona en macOS"
    print_info "Para los demás hosts usa el instalador que les corresponde:"
    print_info "  hosts/debian/install.sh, hosts/synology/install.sh"
    exit 1
fi

print_success "macOS $(sw_vers -productVersion)"

# ============================================================================
# 2. Homebrew
# ============================================================================
# El instalador de Homebrew instala las Xcode Command Line Tools si faltan, y
# con ellas llega git. Por eso este es el primer paso real: antes de Homebrew
# esta máquina no tiene con qué clonar nada.

print_step "Verificando Homebrew..."

if command -v brew &>/dev/null; then
    print_success "Homebrew ya instalado"
else
    print_info "Instalando Homebrew (incluye las Xcode Command Line Tools)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon instala en /opt/homebrew, que no está en el PATH todavía.
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command -v brew &>/dev/null; then
        print_error "Homebrew no quedó en el PATH"
        exit 1
    fi
    print_success "Homebrew instalado"
fi

# ============================================================================
# 3. GitHub CLI
# ============================================================================

print_step "Verificando GitHub CLI..."

if command -v gh &>/dev/null; then
    print_success "GitHub CLI ya instalado"
else
    print_info "Instalando GitHub CLI..."
    brew install gh
    print_success "GitHub CLI instalado"
fi

# ============================================================================
# 4. Autenticación con GitHub
# ============================================================================
# Los scopes por defecto de `gh auth login` son repo, read:org y gist. Registrar
# una llave SSH necesita admin:public_key, que no viene incluido: pedirlo aquí
# evita una segunda vuelta al navegador con `gh auth refresh` más adelante.

print_step "Verificando autenticación con GitHub..."

if gh auth status &>/dev/null && gh auth status 2>&1 | grep -q "admin:public_key"; then
    print_success "Ya autenticado, con permiso para registrar llaves"
else
    print_info "Se abrirá el navegador para autenticar con GitHub"
    gh auth login -h github.com -p https -w -s admin:public_key

    if ! gh auth status &>/dev/null; then
        print_error "Error autenticando con GitHub"
        exit 1
    fi
    print_success "Autenticado con GitHub"
fi

GH_USER=$(gh api user --jq '.login')
print_success "Usuario de GitHub: $GH_USER"

# ============================================================================
# 5. Llave SSH de este equipo
# ============================================================================
# Esto duplica a bin/tools/gh-setup-ssh a propósito: esa herramienta vive dentro
# del repositorio privado, que todavía no se puede clonar. Mantener los dos
# bloques idénticos es lo que hace que ambas vías produzcan la misma llave.

KEY="$HOME/.ssh/id_ed25519"

print_step "Verificando la llave SSH de este equipo..."

if [[ -f "$KEY" ]]; then
    print_success "Ya existe una llave en $KEY"
    ssh-keygen -lf "${KEY}.pub" | awk '{print "  " $2}'
else
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # El comentario es solo etiqueta; sirve para reconocerla en GitHub.
    email="$(git config user.email 2>/dev/null || true)"
    [[ -z "$email" ]] && email="$(whoami)@$(hostname)"

    print_info "Generando la llave de GitHub de este equipo..."
    print_info "Se recomienda ponerle passphrase."
    ssh-keygen -t ed25519 -C "$email" -f "$KEY"

    # En macOS el llavero guarda la passphrase.
    ssh-add --apple-use-keychain "$KEY" 2>/dev/null || \
        print_info "  (no se pudo cargar en el agente; no es bloqueante)"

    print_success "Llave generada"
fi

# ============================================================================
# 6. Registrar la llave en GitHub
# ============================================================================
# Sin navegador: el token del paso 4 ya trae admin:public_key.

print_step "Registrando la llave en GitHub..."

key_fingerprint=$(ssh-keygen -lf "${KEY}.pub" | awk '{print $2}')

if gh ssh-key list 2>/dev/null | grep -q "$key_fingerprint"; then
    print_success "La llave ya estaba registrada"
else
    title="$(scutil --get ComputerName 2>/dev/null || hostname)"
    gh ssh-key add "${KEY}.pub" --title "$title"
    print_success "Llave registrada como: $title"
fi

# Verifica de punta a punta antes de intentar el clon. accept-new agrega la
# huella de GitHub sin preguntar; en una máquina nueva no está en known_hosts y
# el script se detendría esperando un "yes".
print_step "Verificando acceso SSH a GitHub..."

if ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
    print_success "GitHub responde a la llave de este equipo"
else
    print_error "GitHub no reconoció la llave"
    print_info "Revisa con: ssh -vT git@github.com"
    exit 1
fi

# ============================================================================
# 7. Clonar dotfiles y entregar el control
# ============================================================================

print_step "Clonando dotfiles..."

if [[ -d "$DOTFILES_DIR" ]]; then
    print_info "$DOTFILES_DIR ya existe; se conserva y se salta el clon"
else
    git clone --recurse-submodules \
        "git@github.com:${GH_USER}/dotfiles.git" "$DOTFILES_DIR"
    print_success "Dotfiles clonados en $DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

if [[ ! -f "bin/install.sh" ]]; then
    print_error "No se encontró bin/install.sh en $DOTFILES_DIR"
    exit 1
fi

print_header "📦 Instalación"
print_info "A partir de aquí manda el instalador del repositorio."
print_info "Sus logs quedan en ~/.dotfiles-install-logs/"
echo ""

exec bash bin/install.sh --all
