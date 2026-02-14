#!/bin/bash
#
# Módulo: SSH Hardening
# Aplica configurações de segurança no SSH
#

ssh_hardening() {
    log_info "=== Módulo: SSH Hardening ==="
    
    local sshd_config="/etc/ssh/sshd_config"
    local changes_made=false
    
    # Verificar se SSH está instalado
    if ! command -v sshd &> /dev/null; then
        log_warning "SSH server não encontrado, pulando módulo"
        return 0
    fi
    
    # Backup do arquivo de config
    backup_file "$sshd_config"
    
    # Perguntar IP permitido (se não for dry-run)
    local allowed_ip=""
    if [ "$DRY_RUN" = false ]; then
        echo ""
        read -p "Digite o IP que terá acesso SSH (ex: 192.168.1.10) ou pressione Enter para permitir todos: " allowed_ip
        echo ""
    fi
    
    # 1. Desabilitar root login
    log_info "Desabilitando root login via SSH..."
    if grep -q "^PermitRootLogin" "$sshd_config"; then
        execute "sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' $sshd_config"
    else
        execute "echo 'PermitRootLogin no' >> $sshd_config"
    fi
    changes_made=true
    
    # 2. Configurar timeout de sessão (5 minutos)
    log_info "Configurando timeout de sessão SSH (5 minutos)..."
    if grep -q "^ClientAliveInterval" "$sshd_config"; then
        execute "sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 300/' $sshd_config"
    else
        execute "echo 'ClientAliveInterval 300' >> $sshd_config"
    fi
    
    if grep -q "^ClientAliveCountMax" "$sshd_config"; then
        execute "sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 0/' $sshd_config"
    else
        execute "echo 'ClientAliveCountMax 0' >> $sshd_config"
    fi
    changes_made=true
    
    # 3. MaxAuthTries
    log_info "Configurando máximo de 3 tentativas de login..."
    if grep -q "^MaxAuthTries" "$sshd_config"; then
        execute "sed -i 's/^MaxAuthTries.*/MaxAuthTries 3/' $sshd_config"
    else
        execute "echo 'MaxAuthTries 3' >> $sshd_config"
    fi
    changes_made=true
    
    # 4. Protocolo SSH 2 apenas
    log_info "Forçando uso apenas do protocolo SSH 2..."
    if grep -q "^Protocol" "$sshd_config"; then
        execute "sed -i 's/^Protocol.*/Protocol 2/' $sshd_config"
    else
        execute "echo 'Protocol 2' >> $sshd_config"
    fi
    changes_made=true
    
    # 5. Desabilitar X11 Forwarding
    log_info "Desabilitando X11 Forwarding..."
    if grep -q "^X11Forwarding" "$sshd_config"; then
        execute "sed -i 's/^X11Forwarding.*/X11Forwarding no/' $sshd_config"
    else
        execute "echo 'X11Forwarding no' >> $sshd_config"
    fi
    changes_made=true
    
    # 6. Restringir por IP (se fornecido)
    if [ -n "$allowed_ip" ]; then
        log_info "Restringindo SSH ao IP: ${allowed_ip}..."
        
        # Remover AllowUsers anterior se existir
        execute "sed -i '/^AllowUsers/d' $sshd_config"
        
        # Adicionar novo AllowUsers
        # Pegar usuário atual (quem rodou sudo)
        local current_user="${SUDO_USER:-$USER}"
        execute "echo 'AllowUsers ${current_user}@${allowed_ip}' >> $sshd_config"
        changes_made=true
        
        log_warning "ATENÇÃO: SSH agora só aceita conexões de ${allowed_ip}!"
        log_warning "Usuário permitido: ${current_user}"
    fi
    
    # Testar configuração
    if [ "$DRY_RUN" = false ] && [ "$changes_made" = true ]; then
        log_info "Testando configuração do SSH..."
        if sshd -t 2>/dev/null; then
            log_success "Configuração SSH válida"
            
            # Reiniciar SSH
            log_info "Reiniciando serviço SSH..."
            if systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null; then
                log_success "SSH reiniciado com sucesso"
            else
                log_error "Falha ao reiniciar SSH"
                log_warning "Restaurando backup..."
                cp "${BACKUP_DIR}/sshd_config.${TIMESTAMP}.bak" "$sshd_config"
                systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
                return 1
            fi
        else
            log_error "Configuração SSH inválida!"
            log_warning "Restaurando backup..."
            cp "${BACKUP_DIR}/sshd_config.${TIMESTAMP}.bak" "$sshd_config"
            return 1
        fi
    fi
    
    log_success "SSH Hardening aplicado com sucesso"
    echo ""
}
