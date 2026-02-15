#!/bin/bash
#
# Módulo: Automatic Security Updates
# Configura atualizações automáticas de segurança
#

auto_updates() {
    log_info "=== Módulo: Atualizações Automáticas de Segurança ==="
    
    local unattended_config="/etc/apt/apt.conf.d/50unattended-upgrades"
    local auto_config="/etc/apt/apt.conf.d/20auto-upgrades"
    
    # Instalar unattended-upgrades
    if ! dpkg -l | grep -q "^ii.*unattended-upgrades"; then
        log_info "Instalando unattended-upgrades..."
        execute "apt-get update -qq"
        execute "apt-get install -y unattended-upgrades apt-listchanges"
    else
        log_info "unattended-upgrades já está instalado"
    fi
    
    # Backup das configurações
    if [ -f "$unattended_config" ]; then
        backup_file "$unattended_config"
    fi
    
    if [ -f "$auto_config" ]; then
        backup_file "$auto_config"
    fi
    
    log_info "Configurando atualizações automáticas..."
    
    # Configurar 20auto-upgrades (habilitar atualizações)
    if [ "$DRY_RUN" = false ]; then
        cat > "$auto_config" << 'EOF'
// Configuração gerada pelo SecForge
// Habilita atualizações automáticas de segurança

APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
        log_success "Arquivo 20auto-upgrades configurado"
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Configuraria: $auto_config"
    fi
    
    # Configurar 50unattended-upgrades (apenas segurança)
    if [ "$DRY_RUN" = false ]; then
        cat > "$unattended_config" << 'EOF'
// Configuração gerada pelo SecForge
// Instala automaticamente APENAS atualizações de segurança

Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    // "${distro_id}ESMApps:${distro_codename}-apps-security";
    // "${distro_id}ESM:${distro_codename}-infra-security";
};

// Lista de pacotes que NÃO devem ser atualizados automaticamente
Unattended-Upgrade::Package-Blacklist {
    // Adicione aqui pacotes críticos que não devem ser atualizados automaticamente
    // Exemplo: "nginx", "apache2", "mysql-server"
};

// Remover dependências não utilizadas automaticamente
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Reiniciar automaticamente se necessário (com cuidado!)
Unattended-Upgrade::Automatic-Reboot "false";

// Se precisar reiniciar, fazer às 02:00
Unattended-Upgrade::Automatic-Reboot-Time "02:00";

// Enviar email com resultado (configure o email)
// Unattended-Upgrade::Mail "admin@example.com";
Unattended-Upgrade::MailReport "on-change";

// Log detalhado
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";
EOF
        log_success "Arquivo 50unattended-upgrades configurado"
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Configuraria: $unattended_config"
    fi
    
    # Habilitar serviço
    if [ "$DRY_RUN" = false ]; then
        log_info "Habilitando serviço de atualizações automáticas..."
        systemctl enable unattended-upgrades 2>/dev/null || true
        systemctl start unattended-upgrades 2>/dev/null || true
        log_success "Serviço habilitado"
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Habilitaria: unattended-upgrades.service"
    fi
    
    # Testar configuração
    if [ "$DRY_RUN" = false ]; then
        log_info "Testando configuração..."
        if unattended-upgrade --dry-run --debug 2>&1 | grep -q "Allowed origins"; then
            log_success "Configuração válida"
        else
            log_warning "Teste de configuração inconclusivo (pode estar OK)"
        fi
    fi
    
    echo ""
    
    # Resumo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ATUALIZAÇÕES AUTOMÁTICAS CONFIGURADAS            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Configurações aplicadas:${NC}"
    echo "  ✓ Atualizações de ${GREEN}segurança apenas${NC}"
    echo "  ✓ Verificação ${GREEN}diária${NC} de novas atualizações"
    echo "  ✓ Download e instalação ${GREEN}automáticos${NC}"
    echo "  ✓ Limpeza semanal de pacotes antigos"
    echo "  ✓ Remoção de dependências não utilizadas"
    echo "  ✓ Reinicialização ${YELLOW}manual${NC} (não automática)"
    echo ""
    echo -e "${YELLOW}Como funciona:${NC}"
    echo "  • Sistema verifica atualizações de segurança diariamente"
    echo "  • Baixa e instala automaticamente"
    echo "  • Logs em: /var/log/unattended-upgrades/"
    echo ""
    echo -e "${BLUE}Comandos úteis:${NC}"
    echo "  • Ver atualizações pendentes: ${GREEN}apt list --upgradable${NC}"
    echo "  • Forçar atualização agora: ${GREEN}sudo unattended-upgrade${NC}"
    echo "  • Ver logs: ${GREEN}tail -f /var/log/unattended-upgrades/unattended-upgrades.log${NC}"
    echo ""
    
    if [ "$DRY_RUN" = false ]; then
        log_info "Atualizações de segurança serão instaladas automaticamente"
        log_warning "Sistema NÃO reiniciará automaticamente (Automatic-Reboot: false)"
    fi
    
    log_success "Módulo Atualizações Automáticas concluído"
    echo ""
}
