#!/bin/bash
#
# Módulo: Firewall UFW
# Configura firewall com regras básicas de segurança
#

firewall_setup() {
    log_info "=== Módulo: Firewall UFW ==="
    
    # Verificar se UFW está instalado
    if ! command -v ufw &> /dev/null; then
        log_info "UFW não encontrado, instalando..."
        execute "apt-get update -qq"
        execute "apt-get install -y ufw"
    else
        log_info "UFW já está instalado"
    fi
    
    # Perguntas (só se não for dry-run)
    local allow_http="n"
    local allow_https="n"
    local ssh_ip=""
    
    if [ "$DRY_RUN" = false ]; then
        echo ""
        read -p "Permitir HTTP (porta 80)? (s/N): " allow_http
        read -p "Permitir HTTPS (porta 443)? (s/N): " allow_https
        read -p "Restringir SSH a um IP específico? Digite o IP ou pressione Enter para permitir todos: " ssh_ip
        echo ""
    fi
    
    # Resetar UFW para estado limpo
    log_info "Resetando configurações do UFW..."
    execute "ufw --force reset"
    
    # Configurar defaults
    log_info "Configurando políticas padrão..."
    execute "ufw default deny incoming"
    execute "ufw default allow outgoing"
    
    # Permitir SSH
    if [ -n "$ssh_ip" ]; then
        log_info "Permitindo SSH apenas do IP: ${ssh_ip}..."
        execute "ufw allow from ${ssh_ip} to any port 22"
        log_warning "ATENÇÃO: SSH só será acessível de ${ssh_ip}!"
    else
        log_info "Permitindo SSH de qualquer origem..."
        execute "ufw allow 22/tcp"
    fi
    
    # Rate limiting SSH (proteção brute-force)
    log_info "Configurando rate limiting para SSH..."
    execute "ufw limit 22/tcp comment 'Rate limit SSH'"
    
    # HTTP
    if [[ "$allow_http" =~ ^[Ss]$ ]]; then
        log_info "Permitindo HTTP (porta 80)..."
        execute "ufw allow 80/tcp comment 'HTTP'"
    fi
    
    # HTTPS
    if [[ "$allow_https" =~ ^[Ss]$ ]]; then
        log_info "Permitindo HTTPS (porta 443)..."
        execute "ufw allow 443/tcp comment 'HTTPS'"
    fi
    
    # Habilitar UFW
    if [ "$DRY_RUN" = false ]; then
        log_info "Habilitando firewall UFW..."
        # Usar --force para não pedir confirmação
        if ufw --force enable >> "${LOG_FILE}" 2>&1; then
            log_success "UFW habilitado com sucesso"
        else
            log_error "Falha ao habilitar UFW"
            return 1
        fi
        
        # Mostrar status
        log_info "Status do firewall:"
        ufw status verbose | tee -a "${LOG_FILE}"
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Habilitaria: ufw --force enable"
    fi
    
    log_success "Firewall configurado com sucesso"
    echo ""
}
