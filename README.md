# 🛡️ SecForge - Automated Linux Security Hardening

**Hardening automatizado de servidores Linux com foco em segurança proativa**

---

## 📋 Sobre o Projeto

**SecForge** é uma ferramenta de hardening automatizado desenvolvida para aplicar configurações de segurança em servidores Linux de forma rápida, consistente e auditável.

O projeto implementa boas práticas de segurança baseadas em padrões da indústria (CIS Benchmarks, NIST), reduzindo a superfície de ataque e fortalecendo a postura de segurança do sistema.

### Desenvolvido para:
- ✅ Administradores de sistemas
- ✅ Equipes de segurança (Blue Team)
- ✅ Ambientes de laboratório e produção
- ✅ Demonstração de habilidades em hardening

---

## ⚡ Funcionalidades (v2.0-beta)

### **1. SSH Hardening** 🔑
- ✅ Desabilitar login root via SSH
- ✅ Timeout de sessão (5 minutos de inatividade)
- ✅ Restringir SSH a IPs específicos (opcional)
- ✅ Máximo de 3 tentativas de login
- ✅ Forçar protocolo SSH 2
- ✅ Desabilitar X11 Forwarding

### **2. Firewall UFW** 🛡️
- ✅ Configurar políticas padrão (deny incoming, allow outgoing)
- ✅ Permitir SSH com rate limiting (proteção brute-force)
- ✅ Permitir HTTP/HTTPS (opcional)
- ✅ Regras customizadas por IP

### **3. Password Policy** 🔐
- ✅ Senhas fortes obrigatórias:
  - Mínimo 12 caracteres
  - 1 letra maiúscula
  - 1 letra minúscula
  - 1 número
  - 1 caractere especial
  - Máximo 3 caracteres repetidos
- ✅ Impedir reutilização das últimas 5 senhas
- ✅ Validação via PAM

### **4. Desabilitar Serviços** 🚫
- ✅ Desabilita e mascara serviços inseguros:
  - telnet, FTP (vsftpd, proftpd)
  - rsh, rlogin, rexec
  - NIS, TFTP, talk
  - avahi-daemon (mDNS)
  - CUPS (impressão)
  - Bluetooth

### **5. Remover Pacotes** 📦
- ✅ Remove pacotes inseguros/desnecessários:
  - telnet, rsh-client
  - nis, tftp, talk
  - xinetd
- ✅ Limpeza automática de dependências órfãs

### **6. Atualizações Automáticas** 🔄
- ✅ Instala automaticamente atualizações de **segurança apenas**
- ✅ Verificação diária
- ✅ Download e instalação automáticos
- ✅ Limpeza semanal de pacotes antigos
- ✅ Logs detalhados em `/var/log/unattended-upgrades/`

### **7. Proteção Flood** 🌊
- ✅ **SYN Flood Protection**: SYN cookies habilitados
- ✅ **Anti-Spoofing**: Reverse path filtering
- ✅ **Anti-Smurf**: Ignora ICMP broadcasts
- ✅ **Anti-MitM**: Desabilita ICMP redirects
- ✅ **Anti-Source Routing**: Bloqueia roteamento controlado por atacante
- ✅ **Log Martians**: Detecta pacotes suspeitos
- ✅ Configurações de kernel via sysctl

---

## 🚀 Instalação

### Pré-requisitos
- Ubuntu 20.04+ ou Debian 10+
- Acesso root (sudo)
- Bash 5.0+
- Git instalado

### Passo a Passo
```bash
# 1. Clonar repositório
git clone https://github.com/erickalves-lab/secforge.git
cd secforge

# 2. Dar permissão de execução
chmod +x secforge.sh

# 3. Executar (recomendo testar em dry-run primeiro!)
sudo ./secforge.sh --dry-run
```

---

## 📖 Uso

### Modo Dry-Run (Simulação)
**Recomendado para primeira execução!** Mostra o que será feito sem aplicar mudanças:
```bash
sudo ./secforge.sh --dry-run
```

### Modo Real (Aplicar Hardening)
```bash
sudo ./secforge.sh
```

### Opções Disponíveis
```bash
sudo ./secforge.sh --help       # Mostrar ajuda
sudo ./secforge.sh --version    # Mostrar versão
sudo ./secforge.sh --verbose    # Modo detalhado
```

---

## 📊 Exemplo de Saída
```
  ____            _____                    
 / ___|  ___  ___|  ___|__  _ __ __ _  ___ 
 \___ \ / _ \/ __| |_ / _ \| '__/ _` |/ _ \
  ___) |  __/ (__|  _| (_) | | | (_| |  __/
 |____/ \___|\___|_|  \___/|_|  \__, |\___|
                                |___/      
    Automated Linux Security Hardening
    Version: 2.0-beta

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🧪 MODO DRY-RUN ATIVADO
   Nenhuma mudança será aplicada no sistema
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[INFO] === Módulo: SSH Hardening ===
[DRY-RUN] Faria backup: /etc/ssh/sshd_config
[DRY-RUN] Executaria: sed -i 's/^PermitRootLogin.*/PermitRootLogin no/'
...

[INFO] === Módulo: Flood Protection ===
[DRY-RUN] Criaria: /etc/sysctl.d/99-secforge-network.conf
🛡️  SYN Flood Protection
🔒 Anti-Spoofing  
🚫 Anti-DDoS Básico
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ℹ️  Simulação concluída
   Nenhuma mudança foi aplicada
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🏗️ Estrutura do Projeto
```
secforge/
├── secforge.sh              # Script principal
├── modules/                 # Módulos de hardening (Bash)
│   ├── ssh_hardening.sh
│   ├── firewall.sh
│   ├── password_policy.sh
│   ├── disable_services.sh
│   ├── remove_packages.sh
│   ├── auto_updates.sh
│   └── flood_protection.sh
├── lib/
│   └── common.sh           # Funções auxiliares
├── config/
│   └── secforge.conf       # Configurações
├── logs/                   # Logs de execução
├── backups/                # Backups automáticos
└── README.md
```

---

## 🛡️ Recursos de Segurança

### Backups Automáticos
Todos os arquivos modificados são automaticamente salvos em `backups/` com timestamp:
```
backups/sshd_config.20260214_230113.bak
backups/sysctl.conf.20260214_230113.bak
backups/50unattended-upgrades.20260214_230113.bak
```

### Logs Detalhados
Cada execução gera um log completo:
```
logs/secforge_20260214_230113.log
```

### Validação de Configurações
- Testa configuração SSH antes de reiniciar
- Valida regras de firewall
- Verifica políticas de senha
- Testa configurações de kernel

### Rollback Manual
Em caso de erro, os backups permitem restauração:
```bash
sudo cp backups/sshd_config.*.bak /etc/ssh/sshd_config
sudo systemctl restart sshd
```

---

## ⚠️ Avisos Importantes

### **Antes de Executar:**

1. **🧪 SEMPRE teste em dry-run primeiro:**
```bash
   sudo ./secforge.sh --dry-run
```

2. **📸 Faça snapshot/backup da VM** se estiver testando

3. **🔑 Se restringir SSH por IP**, certifique-se de usar o IP correto para não se trancar fora!

4. **📝 Anote as mudanças aplicadas** - os logs ficam em `logs/`

### **Após Executar:**

- ✅ Teste o SSH antes de desconectar
- ✅ Verifique o firewall: `sudo ufw status`
- ✅ Teste criar senha nova: `passwd`
- ✅ Verifique proteções de kernel: `sysctl -a | grep syncookies`
- ✅ Guarde os backups em local seguro

---

## 🧪 Testes

Testado em:
- ✅ Ubuntu 24.04 LTS
- ✅ Ubuntu 22.04 LTS
- ✅ Debian 12

### Como Testar
```bash
# 1. Criar VM limpa Ubuntu/Debian
# 2. Fazer snapshot
# 3. Clonar repositório
# 4. Executar em dry-run
sudo ./secforge.sh --dry-run

# 5. Executar de verdade
sudo ./secforge.sh

# 6. Validar mudanças
sudo sshd -t                              # Testar SSH
sudo ufw status verbose                   # Ver firewall
passwd                                     # Testar senha forte
sysctl -a | grep syncookies               # Ver proteções kernel
sudo systemctl status unattended-upgrades # Ver auto-updates
```

---

## 🗺️ Roadmap

### **Versão 2.0-beta** ✅ (Atual)
- ✅ SSH Hardening
- ✅ Firewall UFW
- ✅ Password Policy
- ✅ Disable Services
- ✅ Remove Packages
- ✅ Auto Updates
- ✅ Flood Protection

### **Versão 2.0** (Em desenvolvimento)
- [ ] Sudo Restrictions (controlar privilégios)
- [ ] Proteção USB (bloquear USB storage)
- [ ] Alerta de usuários inativos (>15 dias)

### **Versão 3.0** (Futuro)
- [ ] Perfis de hardening (minimal, standard, paranoid)
- [ ] Sistema de rollback automático
- [ ] CIS Benchmark compliance check
- [ ] Relatórios em HTML/JSON (Python)
- [ ] Auditd completo
- [ ] Dashboard web (opcional)

---

## 🔬 Detalhes Técnicos

### Proteção Flood - Como Funciona

**SYN Cookies:**
- Protege contra SYN flood sem alocar memória para conexões incompletas
- Gera "cookie" criptográfico ao invés de manter estado
- Valida cliente legítimo quando recebe ACK

**Reverse Path Filtering:**
- Valida se o IP de origem poderia realmente vir da interface de entrada
- Previne IP spoofing e ataques de amplificação

**Anti-Smurf:**
- Ignora pings para broadcast
- Previne participação em ataques de amplificação ICMP

**Configurações aplicadas em:** `/etc/sysctl.d/99-secforge-network.conf`

### Atualizações Automáticas

**Como funciona:**
- Sistema verifica diariamente por atualizações de segurança
- Instala automaticamente apenas patches de segurança
- **NÃO** reinicia automaticamente (requer ação manual)
- Logs em: `/var/log/unattended-upgrades/`

**Comandos úteis:**
```bash
# Ver atualizações pendentes
apt list --upgradable

# Forçar atualização agora
sudo unattended-upgrade

# Ver logs
tail -f /var/log/unattended-upgrades/unattended-upgrades.log
```

---

## 👨‍💻 Autor

**Desenvolvido por:** Erick Alves  
**LinkedIn:** [linkedin.com/erick-alves-sec](https://linkedin.com/erick-alves-sec)  

### Contexto
Este projeto foi desenvolvido como parte do meu portfólio de cibersegurança, demonstrando:
- Automação com Bash
- Hardening de sistemas Linux
- Boas práticas de segurança
- Defesa proativa (Blue Team)
- Conhecimento de SSH, firewall, políticas de senha e proteções de rede
- Integração de múltiplas camadas de defesa

---

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## ⚠️ Disclaimer

**Este projeto é destinado para:**
- ✅ Fins educacionais
- ✅ Ambientes de laboratório controlados
- ✅ Sistemas próprios ou com autorização
- ✅ Demonstração de portfólio profissional

**Importante:**
- Use apenas em sistemas que você possui ou tem autorização
- Teste em ambiente de desenvolvimento antes de produção
- O autor não se responsabiliza por uso indevido

---
