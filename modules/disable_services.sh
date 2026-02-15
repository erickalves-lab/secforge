#!/bin/bash
#
# Módulo: Disable Unnecessary Services
# Desabilita serviços inseguros ou desnecessários
#

disable_services() {
    log_info "=== Módulo: Desabilitar Serviços Desnecessários ==="
    
    # Lista de serviços inseguros/desnecessários
    local services=(
        "telnet"
        "rsh.socket"
        "rlogin.socket"
        "rexec.socket"
        "tftp"
        "vsftpd"
        "proftpd"
        "pure-ftpd"
        "nis"
        "avahi-daemon"
        "cups"
        "cups-browsed"
        "bluetooth"
    )
    
    local disabled_count=0
    local found_services=()
    
    log_info "Verificando serviços instalados..."
    echo ""
    
    for service in "${services[@]}"; do
        # Verificar se o serviço existe (mais rápido)
        if systemctl list-unit-files 2>/dev/null | grep -q "^${service}"; then
            found_services+=("$service")
            
            # Verificar status
            if systemctl is-active --quiet "$service" 2>/dev/null || systemctl is-enabled --quiet "$service" 2>/dev/null; then
                log_warning "Serviço encontrado: ${service}"
                
                # Parar
                execute "systemctl stop ${service} 2>/dev/null || true"
                
                # Desabilitar
                execute "systemctl disable ${service} 2>/dev/null || true"
                
                # Mascarar
                execute "systemctl mask ${service}"
                
                log_success "${service} desabilitado"
                ((disabled_count++))
            fi
        fi
    done
    
    echo ""
    
    # Resumo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         SERVIÇOS VERIFICADOS                          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  📊 Total verificado: ${#services[@]} serviços"
    echo "  ✅ Desabilitados/Mascarados: ${disabled_count}"
    echo "  ℹ️  Não instalados: $((${#services[@]} - ${#found_services[@]}))"
    echo ""
    
    if [ ${#found_services[@]} -gt 0 ]; then
        echo -e "${YELLOW}Serviços processados:${NC}"
        for svc in "${found_services[@]}"; do
            echo "  • ${svc}"
        done
        echo ""
    fi
    
    if [ "$DRY_RUN" = false ] && [ $disabled_count -gt 0 ]; then
        log_info "Para reabilitar um serviço: systemctl unmask <serviço> && systemctl enable <serviço>"
    fi
    
    log_success "Módulo Desabilitar Serviços concluído"
    echo ""
}
