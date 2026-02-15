#!/bin/bash
#
# Módulo: Remove Unnecessary Packages
# Remove pacotes inseguros ou desnecessários
#

remove_packages() {
    log_info "=== Módulo: Remover Pacotes Desnecessários ==="
    
    # Lista de pacotes inseguros/desnecessários
    local packages=(
        "telnet"
        "telnetd"
        "rsh-client"
        "rsh-redone-client"
        "rsh-server"
        "rsh-redone-server"
        "nis"
        "ntalk"
        "talk"
        "talkd"
        "tftp"
        "tftpd"
        "xinetd"
    )
    
    local removed_count=0
    local found_packages=()
    
    log_info "Verificando pacotes instalados..."
    echo ""
    
    for package in "${packages[@]}"; do
        # Verificar se o pacote está instalado
        if dpkg -l | grep -q "^ii.*${package}"; then
            found_packages+=("$package")
            log_warning "Pacote inseguro encontrado: ${package}"
            
            # Remover pacote
            execute "apt-get remove -y ${package}"
            
            log_success "${package} removido"
            ((removed_count++))
        fi
    done
    
    # Limpar pacotes órfãos
    if [ ${#found_packages[@]} -gt 0 ]; then
        log_info "Limpando pacotes órfãos..."
        execute "apt-get autoremove -y"
        execute "apt-get autoclean"
    fi
    
    echo ""
    
    # Resumo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         PACOTES VERIFICADOS                           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  📊 Total verificado: ${#packages[@]} pacotes"
    echo "  ✅ Removidos: ${removed_count}"
    echo "  ℹ️  Não instalados: $((${#packages[@]} - ${#found_packages[@]}))"
    echo ""
    
    if [ ${#found_packages[@]} -gt 0 ]; then
        echo -e "${YELLOW}Pacotes removidos:${NC}"
        for pkg in "${found_packages[@]}"; do
            echo "  • ${pkg}"
        done
        echo ""
    fi
    
    if [ "$DRY_RUN" = false ] && [ $removed_count -gt 0 ]; then
        log_info "Pacotes órfãos foram limpos com apt-get autoremove"
        log_info "Para reinstalar: apt-get install <pacote>"
    fi
    
    log_success "Módulo Remover Pacotes concluído"
    echo ""
}
