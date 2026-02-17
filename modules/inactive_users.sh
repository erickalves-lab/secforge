#!/bin/bash
#
# Módulo: Inactive Users Alert
# Detecta e alerta sobre usuários inativos há mais de 15 dias
#

inactive_users_check() {
    log_info "=== Módulo: Alerta de Usuários Inativos ==="
    
    local python_script="${SCRIPT_DIR}/scripts/check_inactive_users.py"
    
    # Verificar se o script Python existe
    if [ ! -f "$python_script" ]; then
        log_error "Script Python não encontrado: $python_script"
        return 1
    fi
    
    # Verificar se Python3 está instalado
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 não encontrado. Instale: apt-get install python3"
        return 1
    fi
    
    echo ""
    log_info "Executando verificação de usuários inativos..."
    echo ""
    
    # Executar script Python
    if [ "$DRY_RUN" = false ]; then
        python3 "$python_script"
        local exit_code=$?
        
        if [ $exit_code -eq 1 ]; then
            log_warning "Usuários inativos detectados! Verifique o relatório acima."
        elif [ $exit_code -eq 0 ]; then
            log_success "Nenhum usuário inativo detectado"
        else
            log_error "Erro ao executar verificação"
            return 1
        fi
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Executaria: python3 $python_script"
        echo ""
        echo -e "${BLUE}O que seria verificado:${NC}"
        echo "  • Usuários reais (UID >= 1000)"
        echo "  • Último login de cada usuário"
        echo "  • Inatividade superior a 15 dias"
        echo "  • Usuários que nunca fizeram login"
    fi
    
    echo ""
    log_success "Módulo Alerta Usuários Inativos concluído"
    echo ""
}
