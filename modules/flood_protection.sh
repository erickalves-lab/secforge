#!/bin/bash
#
# Módulo: Flood Protection
# Configura proteções de kernel contra ataques de rede
#

flood_protection() {
    log_info "=== Módulo: Proteção Básica contra Flood ==="
    
    local sysctl_conf="/etc/sysctl.conf"
    local custom_conf="/etc/sysctl.d/99-secforge-network.conf"
    
    # Backup do sysctl.conf
    backup_file "$sysctl_conf"
    
    log_info "Configurando proteções de rede no kernel..."
    
    # Criar arquivo de configuração customizado
    if [ "$DRY_RUN" = false ]; then
        cat > "$custom_conf" << 'EOF'
###############################################################################
# SecForge - Network Security Configuration
# Proteções contra ataques de rede (SYN flood, spoofing, etc)
###############################################################################

# SYN Flood Protection
# Habilita SYN cookies quando a fila de SYN está cheia
net.ipv4.tcp_syncookies = 1

# Aumentar backlog de conexões para suportar mais conexões simultâneas
net.ipv4.tcp_max_syn_backlog = 2048
net.core.netdev_max_backlog = 2000

# IP Spoofing Protection (Reverse Path Filtering)
# Valida que pacotes vêm de interfaces esperadas
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignorar ICMP broadcasts (Anti-Smurf attack)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignorar mensagens ICMP de erro mal formadas
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Desabilitar ICMP redirects (Anti-spoofing)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Não enviar ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Desabilitar source routing (Anti-spoofing)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Log de pacotes suspeitos (martians)
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Proteção contra fragmentação de pacotes
net.ipv4.ipfrag_high_thresh = 262144
net.ipv4.ipfrag_low_thresh = 196608

# Tempo de vida de conexões
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Desabilitar IPv6 se não for usado (opcional)
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1
EOF
        log_success "Arquivo de configuração criado: $custom_conf"
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Criaria: $custom_conf"
    fi
    
    # Aplicar configurações
    if [ "$DRY_RUN" = false ]; then
        log_info "Aplicando configurações do kernel..."
        if sysctl -p "$custom_conf" >> "${LOG_FILE}" 2>&1; then
            log_success "Configurações de kernel aplicadas"
        else
            log_warning "Algumas configurações podem não ter sido aplicadas (verifique o log)"
        fi
        
        # Aplicar sysctl.conf também (para garantir)
        sysctl -p >> "${LOG_FILE}" 2>&1 || true
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Executaria: sysctl -p $custom_conf"
    fi
    
    echo ""
    
    # Resumo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      PROTEÇÃO CONTRA FLOOD CONFIGURADA                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Proteções de Rede Habilitadas:${NC}"
    echo ""
    echo -e "${GREEN}🛡️  SYN Flood Protection${NC}"
    echo "  ✓ SYN cookies habilitados"
    echo "  ✓ Backlog aumentado (2048 conexões)"
    echo ""
    echo -e "${GREEN}🔒 Anti-Spoofing${NC}"
    echo "  ✓ Reverse path filtering ativo"
    echo "  ✓ Source routing desabilitado"
    echo "  ✓ ICMP redirects bloqueados"
    echo ""
    echo -e "${GREEN}🚫 Anti-DDoS Básico${NC}"
    echo "  ✓ ICMP broadcasts ignorados (anti-Smurf)"
    echo "  ✓ Erros ICMP malformados ignorados"
    echo "  ✓ Log de pacotes suspeitos (martians)"
    echo ""
    echo -e "${YELLOW}Arquivo de configuração:${NC}"
    echo "  • $custom_conf"
    echo ""
    echo -e "${BLUE}Comandos úteis:${NC}"
    echo "  • Ver configurações: ${GREEN}sysctl -a | grep -E 'syncookies|rp_filter|redirects'${NC}"
    echo "  • Recarregar config: ${GREEN}sudo sysctl -p $custom_conf${NC}"
    echo "  • Ver pacotes suspeitos: ${GREEN}dmesg | grep martian${NC}"
    echo ""
    
    if [ "$DRY_RUN" = false ]; then
        log_info "Proteções de rede aplicadas permanentemente"
        log_info "Configurações serão recarregadas automaticamente após reboot"
    fi
    
    log_success "Módulo Proteção Flood concluído"
    echo ""
}
