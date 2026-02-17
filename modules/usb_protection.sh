#!/bin/bash
#
# Módulo: USB Protection
# Bloqueia USB storage devices (pendrive, HD externo)
# Mantém funcionando: teclado, mouse, impressora, webcam
#

usb_protection() {
    log_info "=== Módulo: Proteção USB ==="
    
    local modprobe_conf="/etc/modprobe.d/secforge-usb-block.conf"
    
    log_info "Configurando bloqueio de USB storage..."
    
    # Criar configuração de blacklist
    if [ "$DRY_RUN" = false ]; then
        cat > "$modprobe_conf" << 'EOF'
# SecForge - USB Storage Protection
# Bloqueia pendrives e HDs externos USB
# Periféricos USB (teclado, mouse, impressora) continuam funcionando

# Bloquear módulo de armazenamento USB
blacklist usb-storage

# Impedir que seja carregado automaticamente
install usb-storage /bin/true
EOF
        log_success "Arquivo de bloqueio criado: $modprobe_conf"
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Criaria: $modprobe_conf"
    fi
    
    # Remover módulo se já estiver carregado
    if [ "$DRY_RUN" = false ]; then
        log_info "Removendo módulo usb-storage se estiver carregado..."
        if lsmod | grep -q usb_storage; then
            if rmmod usb_storage 2>/dev/null; then
                log_success "Módulo usb-storage removido"
            else
                log_warning "Não foi possível remover módulo (pode estar em uso)"
            fi
        else
            log_info "Módulo usb-storage não estava carregado"
        fi
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Executaria: rmmod usb-storage"
    fi
    
    # Atualizar initramfs (para aplicar no boot)
    if [ "$DRY_RUN" = false ]; then
        log_info "Atualizando initramfs..."
        if update-initramfs -u >> "${LOG_FILE}" 2>&1; then
            log_success "Initramfs atualizado"
        else
            log_warning "Falha ao atualizar initramfs (não crítico)"
        fi
    else
        echo -e "${YELLOW}[DRY-RUN]${NC} Executaria: update-initramfs -u"
    fi
    
    echo ""
    
    # Resumo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         PROTEÇÃO USB CONFIGURADA                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}🚫 Dispositivos BLOQUEADOS:${NC}"
    echo "  ✗ Pendrives USB"
    echo "  ✗ HDs externos USB"
    echo "  ✗ SSDs externos USB"
    echo "  ✗ Cartões de memória via USB"
    echo ""
    echo -e "${GREEN}✅ Dispositivos PERMITIDOS:${NC}"
    echo "  ✓ Teclado USB"
    echo "  ✓ Mouse USB"
    echo "  ✓ Impressora USB"
    echo "  ✓ Webcam USB"
    echo "  ✓ Scanner USB"
    echo ""
    echo -e "${BLUE}Como funciona:${NC}"
    echo "  • Módulo do kernel 'usb-storage' bloqueado"
    echo "  • Sistema operacional não reconhece dispositivos de armazenamento"
    echo "  • Proteção contra malware via pendrive"
    echo "  • Prevenção de exfiltração de dados"
    echo ""
    echo -e "${YELLOW}Para desbloquear temporariamente:${NC}"
    echo "  \$ sudo modprobe usb-storage"
    echo ""
    echo -e "${YELLOW}Para desbloquear permanentemente:${NC}"
    echo "  \$ sudo rm $modprobe_conf"
    echo "  \$ sudo update-initramfs -u"
    echo "  \$ sudo reboot"
    echo ""
    
    if [ "$DRY_RUN" = false ]; then
        log_warning "USB storage devices bloqueados"
        log_info "Reinicie o sistema para garantir que a proteção seja aplicada completamente"
    fi
    
    log_success "Módulo Proteção USB concluído"
    echo ""
}
