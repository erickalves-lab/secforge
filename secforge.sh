#!/bin/bash
#
# SecForge - Automated Linux Security Hardening
# 
# Aplica configurações de segurança em servidores Linux
# Suporta modo dry-run para simulação sem aplicar mudanças
#
# Uso:
#   sudo ./secforge.sh              # Aplicar hardening
#   sudo ./secforge.sh --dry-run    # Simular (não aplica)
#   sudo ./secforge.sh --help       # Ajuda
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ============================================================================
# VARIÁVEIS GLOBAIS
# ============================================================================

VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
BACKUP_DIR="${SCRIPT_DIR}/backups"
CONFIG_DIR="${SCRIPT_DIR}/config"
MODULES_DIR="${SCRIPT_DIR}/modules"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/secforge_${TIMESTAMP}.log"

DRY_RUN=false
VERBOSE=false

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

# Logging
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}"
}

# Executar comando (respeita dry-run)
execute() {
    local cmd="$*"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Executaria: ${cmd}" | tee -a "${LOG_FILE}"
        return 0
    else
        log_info "Executando: ${cmd}"
        if eval "$cmd" >> "${LOG_FILE}" 2>&1; then
            return 0
        else
            log_error "Falha ao executar: ${cmd}"
            return 1
        fi
    fi
}

# Backup de arquivo
backup_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        log_warning "Arquivo não existe: ${file}"
        return 1
    fi
    
    local backup_path="${BACKUP_DIR}/$(basename ${file}).${TIMESTAMP}.bak"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Faria backup: ${file} -> ${backup_path}"
    else
        cp -p "$file" "$backup_path"
        log_success "Backup criado: ${backup_path}"
    fi
}

# Verificar se está rodando como root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script precisa ser executado como root (use sudo)"
        exit 1
    fi
}

# Detectar distribuição Linux
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
        log_info "Distribuição detectada: ${DISTRO} ${DISTRO_VERSION}"
    else
        log_error "Não foi possível detectar a distribuição Linux"
        exit 1
    fi
    
    # Verificar se é suportada
    case "$DISTRO" in
        ubuntu|debian)
            log_success "Distribuição suportada"
            ;;
        *)
            log_warning "Distribuição não testada oficialmente: ${DISTRO}"
            read -p "Continuar mesmo assim? (s/N): " confirm
            [[ ! "$confirm" =~ ^[Ss]$ ]] && exit 0
            ;;
    esac
}

# Banner
show_banner() {
    cat << "EOF"
  ____            _____                    
 / ___|  ___  ___|  ___|__  _ __ __ _  ___ 
 \___ \ / _ \/ __| |_ / _ \| '__/ _` |/ _ \
  ___) |  __/ (__|  _| (_) | | | (_| |  __/
 |____/ \___|\___|_|  \___/|_|  \__, |\___|
                                |___/      
    Automated Linux Security Hardening
    Version: 2.0.0
EOF
    echo ""
}

# Ajuda
show_help() {
    cat << EOF
Uso: sudo ./secforge.sh [OPÇÕES]

Opções:
  --dry-run         Simular execução sem aplicar mudanças
  --verbose         Mostrar output detalhado
  --help            Mostrar esta mensagem
  --version         Mostrar versão

Exemplos:
  sudo ./secforge.sh                  # Aplicar hardening
  sudo ./secforge.sh --dry-run        # Simular (não aplica)
  sudo ./secforge.sh --dry-run --verbose  # Simular com detalhes

Módulos aplicados:
  1. SSH Hardening         - Desabilitar root, timeout, IP whitelist
  2. Firewall UFW          - Configurar firewall
  3. Password Policy       - Senhas fortes obrigatórias
  4. Disable Services      - Desabilitar serviços inseguros
  5. Remove Packages       - Remover pacotes desnecessários
  6. Auto Updates          - Atualizações automáticas de segurança
  7. Flood Protection      - Proteção contra SYN flood e spoofing
  8. USB Protection        - Bloqueio de USB storage
  9. Sudo Restrictions     - Controlar quem tem privilégios sudo
  10. Inactive Users       - Alertar sobre usuários inativos

Para mais informações: https://github.com/erickalves-lab/secforge
EOF
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Processar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            --version)
                echo "SecForge v${VERSION}"
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Criar diretórios se não existirem
    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}"
    
    # Iniciar
    show_banner
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}   🧪 MODO DRY-RUN ATIVADO${NC}"
        echo -e "${YELLOW}   Nenhuma mudança será aplicada no sistema${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi
    
    log_info "Iniciando SecForge v${VERSION}"
    log_info "Log: ${LOG_FILE}"
    
    # Verificações
    check_root
    detect_distro
    
    echo ""
    log_info "Iniciando hardening..."
    echo ""
    
    # Carregar módulos
    if [ -f "${MODULES_DIR}/ssh_hardening.sh" ]; then
        source "${MODULES_DIR}/ssh_hardening.sh"
    fi
    
    if [ -f "${MODULES_DIR}/firewall.sh" ]; then
        source "${MODULES_DIR}/firewall.sh"
    fi
    
    if [ -f "${MODULES_DIR}/password_policy.sh" ]; then
        source "${MODULES_DIR}/password_policy.sh"
    fi
    
    if [ -f "${MODULES_DIR}/disable_services.sh" ]; then
        source "${MODULES_DIR}/disable_services.sh"
    fi
    
    if [ -f "${MODULES_DIR}/remove_packages.sh" ]; then
        source "${MODULES_DIR}/remove_packages.sh"
    fi
    
    if [ -f "${MODULES_DIR}/auto_updates.sh" ]; then
        source "${MODULES_DIR}/auto_updates.sh"
    fi
    
    if [ -f "${MODULES_DIR}/flood_protection.sh" ]; then
        source "${MODULES_DIR}/flood_protection.sh"
    fi
    
    if [ -f "${MODULES_DIR}/usb_protection.sh" ]; then
        source "${MODULES_DIR}/usb_protection.sh"
    fi
    
    if [ -f "${MODULES_DIR}/sudo_restrictions.sh" ]; then
        source "${MODULES_DIR}/sudo_restrictions.sh"
    fi
    
    if [ -f "${MODULES_DIR}/inactive_users.sh" ]; then
        source "${MODULES_DIR}/inactive_users.sh"
    fi
    
    # Executar módulos
    if [ -f "${MODULES_DIR}/ssh_hardening.sh" ]; then
        ssh_hardening
    fi
    
    if [ -f "${MODULES_DIR}/firewall.sh" ]; then
        firewall_setup
    fi
    
    if [ -f "${MODULES_DIR}/password_policy.sh" ]; then
        password_policy
    fi
    
    if [ -f "${MODULES_DIR}/disable_services.sh" ]; then
        disable_services
    fi
    
    if [ -f "${MODULES_DIR}/remove_packages.sh" ]; then
        remove_packages
    fi
    
    if [ -f "${MODULES_DIR}/auto_updates.sh" ]; then
        auto_updates
    fi
    
    if [ -f "${MODULES_DIR}/flood_protection.sh" ]; then
        flood_protection
    fi
    
    if [ -f "${MODULES_DIR}/usb_protection.sh" ]; then
        usb_protection
    fi
    
    if [ -f "${MODULES_DIR}/sudo_restrictions.sh" ]; then
        sudo_restrictions
    fi
    
    if [ -f "${MODULES_DIR}/inactive_users.sh" ]; then
        inactive_users_check
    fi
    
    echo ""
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}   ℹ️  Simulação concluída${NC}"
        echo -e "${YELLOW}   Nenhuma mudança foi aplicada${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}   ✅ Hardening aplicado com sucesso!${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
    
    echo ""
    log_success "SecForge concluído"
    log_info "Log completo: ${LOG_FILE}"
}

# Executar
main "$@"
