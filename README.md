# 🛡️ SecForge - Automated Linux Security Hardening

**Hardening automatizado de servidores Linux com foco em segurança proativa**

---

## 📋 Sobre o Projeto

**SecForge** é uma ferramenta de hardening automatizado desenvolvida para aplicar configurações de segurança em servidores Linux de forma rápida, consistente e auditável.

O projeto implementa boas práticas de segurança baseadas em padrões da indústria, reduzindo a superfície de ataque e fortalecendo a postura de segurança do sistema.

### Desenvolvido para:
- ✅ Administradores de sistemas
- ✅ Equipes de segurança (Blue Team)
- ✅ Ambientes de laboratório e produção
- ✅ Demonstração de habilidades em hardening

---

## ⚡ Funcionalidades (v1.0)

### **1. SSH Hardening**
- ✅ Desabilitar login root via SSH
- ✅ Timeout de sessão (5 minutos de inatividade)
- ✅ Restringir SSH a IPs específicos (opcional)
- ✅ Máximo de 3 tentativas de login
- ✅ Forçar protocolo SSH 2
- ✅ Desabilitar X11 Forwarding

### **2. Firewall UFW**
- ✅ Configurar políticas padrão (deny incoming, allow outgoing)
- ✅ Permitir SSH com rate limiting (proteção brute-force)
- ✅ Permitir HTTP/HTTPS (opcional)
- ✅ Regras customizadas por IP

### **3. Password Policy**
- ✅ Senhas fortes obrigatórias:
  - Mínimo 12 caracteres
  - 1 letra maiúscula
  - 1 letra minúscula
  - 1 número
  - 1 caractere especial
- ✅ Impedir reutilização das últimas 5 senhas
- ✅ Máximo 3 caracteres repetidos consecutivos

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
    Version: 1.0.0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🧪 MODO DRY-RUN ATIVADO
   Nenhuma mudança será aplicada no sistema
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[INFO] === Módulo: SSH Hardening ===
[DRY-RUN] Faria backup: /etc/ssh/sshd_config
[DRY-RUN] Executaria: sed -i 's/^PermitRootLogin.*/PermitRootLogin no/'
...
[OK] SSH Hardening aplicado com sucesso

[INFO] === Módulo: Firewall UFW ===
[DRY-RUN] Executaria: ufw default deny incoming
...
[OK] Firewall configurado com sucesso

[INFO] === Módulo: Password Policy ===
[DRY-RUN] Configuraria: /etc/security/pwquality.conf
...
[OK] Password Policy configurado com sucesso
```

---

## 🏗️ Estrutura do Projeto
```
secforge/
├── secforge.sh              # Script principal
├── modules/                 # Módulos de hardening
│   ├── ssh_hardening.sh
│   ├── firewall.sh
│   └── password_policy.sh
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
backups/sshd_config.20260214_164312.bak
backups/common-password.20260214_164312.bak
```

### Logs Detalhados
Cada execução gera um log completo:
```
logs/secforge_20260214_164312.log
```

### Validação de Configurações
- Testa configuração SSH antes de reiniciar
- Valida regras de firewall
- Verifica políticas de senha

### Rollback
Em caso de erro, os backups permitem restauração manual:
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
sudo sshd -t                    # Testar SSH
sudo ufw status verbose         # Ver firewall
passwd                          # Testar senha forte
```

---

## 🗺️ Roadmap

### **Versão 1.0** ✅ (Atual)
- ✅ SSH Hardening
- ✅ Firewall UFW
- ✅ Password Policy

### **Versão 2.0** (Planejado)
- [ ] Desabilitar serviços desnecessários
- [ ] Remover pacotes inseguros
- [ ] Atualizações automáticas de segurança
- [ ] Proteção contra SYN flood
- [ ] Restrições de sudo
- [ ] Proteção USB
- [ ] Alerta de usuários inativos

### **Versão 3.0** (Futuro)
- [ ] Perfis de hardening (minimal, standard, paranoid)
- [ ] Sistema de rollback automático
- [ ] CIS Benchmark compliance check
- [ ] Relatórios em HTML/JSON
- [ ] Auditd completo

---

## 👨‍💻 Autor

**Desenvolvido por:** [Seu Nome]  
**LinkedIn:** [Seu LinkedIn]  

### Contexto
Este projeto foi desenvolvido como parte do meu portfólio de cibersegurança, demonstrando:
- Automação com Bash
- Hardening de sistemas Linux
- Boas práticas de segurança
- Defesa proativa (Blue Team)
- Conhecimento de SSH, firewall e políticas de senha

---

---

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
```
MIT License

Copyright (c) 2026 [Seu Nome]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

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

**⭐ Se este projeto foi útil, considere dar uma estrela.**
