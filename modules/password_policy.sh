#!/bin/bash
#
# Módulo: Password Policy
# Configura políticas de senha forte
#

password_policy() {
    log_info "=== Módulo: Password Policy ==="
    
    local pwquality_conf="/etc/security/pwquality.conf"
    local pam_common_password="/etc/pam.d/common-password"
    
    # Instalar libpam-pwquality
    if ! dpkg -l | grep -q libpam-pwquality; then
        log_info "Instalando libpam-pwquality..."
        execute "apt-get update -qq"
        execute "apt-get install -y libpam-pwquality"
    else
        log_info "libpam-pwquality já está instalado"
    fi
    
    # Backup dos arquivos de configuração
    backup_file "$pwquality_conf"
    backup_file "$pam_common_password"
    
    log_info "Configurando política de senhas fortes..."
    
    # Configurar pwquality.conf
    log_info "Aplicando regras de complexidade de senha..."
    
    if [ "$DRY_RUN" = false ]; then
        # Criar configuração limpa no pwquality.conf
        cat > "$pwquality_conf" << 'EOF'
# Configuração gerada pelo SecForge
# Política de senha forte

# Tamanho mínimo da senha
minlen = 12

# Número mínimo de dígitos (número)
dcredit = -1

# Número mínimo de caracteres maiúsculos
ucredit = -1

# Número mínimo de caracteres minúsculos
lcredit = -1

# Número mínimo de caracteres especiais
ocredit = -1

# Número máximo de caracteres consecutivos repetidos
maxrepeat = 3

# Verificar contra dicionário
dictcheck = 1
EOF
        log_success "Arquivo pwquality.conf configurado"
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Configuraria: $pwquality_conf"
    fi
    
    # Configurar PAM para histórico de senhas
    log_info "Configurando histórico de senhas (impede reutilização)..."
    
    if [ "$DRY_RUN" = false ]; then
        # Fazer backup adicional
        cp "$pam_common_password" "${pam_common_password}.secforge_backup"
        
        # Remover linhas antigas de pwhistory se existirem
        sed -i '/pam_pwhistory.so/d' "$pam_common_password"
        
        # Adicionar pwhistory ANTES do pam_unix.so com use_authtok
        sed -i '/^password.*pam_unix.so/i password required pam_pwhistory.so remember=5 use_authtok' "$pam_common_password"
        
        log_success "Histórico de senhas configurado"
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Configuraria histórico de senhas em: $pam_common_password"
    fi
    
    # Mostrar configuração aplicada
    if [ "$DRY_RUN" = false ]; then
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║         POLÍTICA DE SENHA CONFIGURADA                 ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${BLUE}Requisitos para novas senhas:${NC}"
        echo "  ✓ Mínimo ${GREEN}12 caracteres${NC}"
        echo "  ✓ Pelo menos ${GREEN}1 letra MAIÚSCULA${NC} (A-Z)"
        echo "  ✓ Pelo menos ${GREEN}1 letra minúscula${NC} (a-z)"
        echo "  ✓ Pelo menos ${GREEN}1 número${NC} (0-9)"
        echo "  ✓ Pelo menos ${GREEN}1 caractere especial${NC} (!@#\$%&*)"
        echo "  ✓ Não pode reutilizar últimas ${GREEN}5 senhas${NC}"
        echo "  ✓ Máximo ${GREEN}3 caracteres repetidos${NC} consecutivos"
        echo ""
        echo -e "${YELLOW}Exemplos de senhas VÁLIDAS:${NC}"
        echo "  • Minha@Senha123"
        echo "  • SecForge#2026!"
        echo "  • P@ssw0rd_Forte"
        echo ""
        echo -e "${RED}Exemplos de senhas INVÁLIDAS:${NC}"
        echo "  ✗ senha123        (falta maiúscula e especial)"
        echo "  ✗ Senha123        (falta caractere especial)"
        echo "  ✗ Senha@          (muito curta, falta número)"
        echo "  ✗ 123456          (muito curta, sem letras)"
        echo "  ✗ Senhaaa@123     (muitos 'a' repetidos)"
        echo ""
        echo -e "${BLUE}Para testar/mudar sua senha:${NC}"
        echo "  \$ passwd"
        echo ""
        echo -e "${YELLOW}NOTA:${NC} Política afeta apenas ${YELLOW}NOVAS${NC} senhas criadas a partir de agora."
        echo ""
        
        # Testar se PAM está OK
        log_info "Validando configuração PAM..."
        if grep -q "pam_pwhistory.so" "$pam_common_password" && grep -q "pam_pwquality.so" "$pam_common_password"; then
            log_success "Configuração PAM válida"
        else
            log_warning "Configuração PAM pode estar incompleta, verifique manualmente"
        fi
    fi
    
    log_success "Password Policy configurado com sucesso"
    echo ""
}
