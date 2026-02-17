#!/bin/bash
#
# Módulo: Sudo Restrictions
# Controla quem tem privilégios sudo
#

sudo_restrictions() {
    log_info "=== Módulo: Restrições de Sudo ==="
    
    local authorized_file="${CONFIG_DIR}/authorized_sudo_users.txt"
    local sudo_group="sudo"
    
    # Verificar se arquivo de usuários autorizados existe
    if [ ! -f "$authorized_file" ]; then
        log_warning "Arquivo de usuários autorizados não encontrado: $authorized_file"
        log_info "Criando arquivo de exemplo..."
        
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$CONFIG_DIR"
            cat > "$authorized_file" << EOF
# SecForge - Usuários Autorizados a ter Sudo
# Um usuário por linha
# Linhas começando com # são ignoradas

# Exemplo:
# admin
# operador
# seu_usuario

# Adicione os usuários autorizados abaixo:
${SUDO_USER:-root}
EOF
            log_success "Arquivo criado: $authorized_file"
            log_info "EDITE o arquivo e adicione os usuários autorizados!"
            echo ""
            echo -e "${YELLOW}IMPORTANTE:${NC}"
            echo "  1. Edite: nano $authorized_file"
            echo "  2. Adicione os usuários que DEVEM ter sudo"
            echo "  3. Execute o SecForge novamente"
            echo ""
            log_warning "Pulando módulo por enquanto (arquivo precisa ser configurado)"
            return 0
        else
            echo -e "${YELLOW}[DRY-RUN]${NC} Criaria arquivo: $authorized_file"
            return 0
        fi
    fi
    
    # Ler usuários autorizados
    local authorized_users=()
    while IFS= read -r line; do
        # Ignorar linhas vazias e comentários
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        # Remover espaços em branco
        line=$(echo "$line" | xargs)
        authorized_users+=("$line")
    done < "$authorized_file"
    
    if [ ${#authorized_users[@]} -eq 0 ]; then
        log_error "Nenhum usuário autorizado encontrado em $authorized_file"
        log_warning "Pulando módulo (adicione pelo menos um usuário)"
        return 1
    fi
    
    log_info "Usuários autorizados a ter sudo: ${authorized_users[*]}"
    echo ""
    
    # Listar usuários com sudo atualmente
    log_info "Verificando usuários com sudo..."
    local current_sudo_users=()
    
    # Usuários no grupo sudo
    if getent group "$sudo_group" &>/dev/null; then
        local group_members=$(getent group "$sudo_group" | cut -d: -f4)
        if [ -n "$group_members" ]; then
            IFS=',' read -ra members <<< "$group_members"
            current_sudo_users+=("${members[@]}")
        fi
    fi
    
    echo ""
    
    # Processar usuários
    local removed_count=0
    local kept_count=0
    
    for user in "${current_sudo_users[@]}"; do
        # Verificar se está na lista de autorizados
        if [[ " ${authorized_users[*]} " =~ " ${user} " ]]; then
            log_info "✓ Usuário ${user} está autorizado (mantido)"
            ((kept_count++))
        else
            log_warning "✗ Usuário ${user} NÃO está autorizado"
            
            # Remover do grupo sudo
            execute "deluser ${user} ${sudo_group}"
            
            log_success "Sudo removido de: ${user}"
            ((removed_count++))
        fi
    done
    
    echo ""
    
    # Resumo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         RESTRIÇÕES DE SUDO APLICADAS                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  📊 Total com sudo antes: ${#current_sudo_users[@]}"
    echo "  ✅ Mantidos: ${kept_count}"
    echo "  🚫 Removidos: ${removed_count}"
    echo ""
    
    if [ ${#authorized_users[@]} -gt 0 ]; then
        echo -e "${GREEN}Usuários autorizados:${NC}"
        for user in "${authorized_users[@]}"; do
            echo "  • ${user}"
        done
        echo ""
    fi
    
    if [ $removed_count -gt 0 ]; then
        echo -e "${YELLOW}Usuários que perderam sudo:${NC}"
        for user in "${current_sudo_users[@]}"; do
            if [[ ! " ${authorized_users[*]} " =~ " ${user} " ]]; then
                echo "  • ${user}"
            fi
        done
        echo ""
    fi
    
    echo -e "${BLUE}Como adicionar sudo de volta:${NC}"
    echo "  \$ sudo usermod -aG sudo <usuario>"
    echo ""
    echo -e "${BLUE}Arquivo de configuração:${NC}"
    echo "  $authorized_file"
    echo ""
    
    if [ "$DRY_RUN" = false ]; then
        log_info "Restrições de sudo aplicadas com sucesso"
    fi
    
    log_success "Módulo Sudo Restrictions concluído"
    echo ""
}
