#!/usr/bin/env python3
"""
SecForge - Check Inactive Users
Detecta usuários que não fazem login há mais de 15 dias
"""

import subprocess
import sys
import os
import locale
from datetime import datetime, timedelta
import pwd

# Configurações
INACTIVE_DAYS = 15
MIN_UID = 1000  # Usuários de sistema (< 1000) são ignorados

def get_last_login(username):
    """
    Obtém data do último login de um usuário
    Retorna None se nunca fez login
    """
    try:
        # Forçar locale inglês
        env = os.environ.copy()
        env['LC_TIME'] = 'C'
        env['LANG'] = 'C'
        
        # Usar comando lastlog com locale inglês
        result = subprocess.run(
            ['lastlog', '-u', username],
            capture_output=True,
            text=True,
            timeout=5,
            env=env
        )
        
        if result.returncode != 0:
            return None
        
        lines = result.stdout.strip().split('\n')
        
        if len(lines) < 2:
            return None
        
        # Pegar segunda linha (primeira é header)
        last_login_line = lines[1]
        
        # Se nunca fez login
        if '**Never logged in**' in last_login_line:
            return None
        
        # Parsear data
        # Formato esperado: username port from day month date time timezone year
        # Exemplo: sm       pts/0    192.168.122.1 Mon Feb 16 22:18:29 -0300 2026
        parts = last_login_line.split()
        
        if len(parts) < 9:
            return None
        
        try:
            # Pegar as partes da data: day month date time timezone year
            date_str = ' '.join(parts[3:9])
            
            # Parsear com formato inglês
            return datetime.strptime(date_str, '%a %b %d %H:%M:%S %z %Y')
            
        except Exception as e:
            # Se falhar, tentar sem timezone
            try:
                date_str = ' '.join(parts[3:8])
                dt = datetime.strptime(date_str, '%a %b %d %H:%M:%S %Y')
                return dt
            except:
                return None
            
    except Exception as e:
        print(f"Erro ao verificar {username}: {e}", file=sys.stderr)
        return None

def get_real_users():
    """
    Retorna lista de usuários reais (UID >= 1000)
    Exclui usuários de sistema
    """
    real_users = []
    
    try:
        for user in pwd.getpwall():
            username = user.pw_name
            uid = user.pw_uid
            shell = user.pw_shell
            
            # Ignorar usuários de sistema
            if uid < MIN_UID:
                continue
            
            # Ignorar usuários sem shell válido
            if 'nologin' in shell or 'false' in shell:
                continue
            
            real_users.append(username)
    
    except Exception as e:
        print(f"Erro ao listar usuários: {e}", file=sys.stderr)
    
    return real_users

def main():
    """Função principal"""
    
    print("🔍 SecForge - Verificação de Usuários Inativos")
    print("=" * 60)
    print()
    
    # Data de corte (15 dias atrás)
    from datetime import timezone
    cutoff_date = datetime.now(timezone.utc) - timedelta(days=INACTIVE_DAYS)
    
    # Obter usuários reais
    users = get_real_users()
    
    if not users:
        print("⚠️  Nenhum usuário real encontrado (UID >= 1000)")
        return 0
    
    print(f"📋 Verificando {len(users)} usuário(s)...")
    print(f"⏰ Limite: {INACTIVE_DAYS} dias de inatividade")
    print()
    
    # Verificar cada usuário
    inactive_users = []
    never_logged = []
    active_users = []
    
    for username in users:
        last_login = get_last_login(username)
        
        if last_login is None:
            never_logged.append(username)
        elif last_login < cutoff_date:
            days_inactive = (datetime.now(timezone.utc) - last_login).days
            inactive_users.append((username, last_login, days_inactive))
        else:
            days_since = (datetime.now(timezone.utc) - last_login).days
            active_users.append((username, last_login, days_since))
    
    # Relatório
    print("=" * 60)
    print("📊 RESULTADO DA VERIFICAÇÃO")
    print("=" * 60)
    print()
    
    # Usuários inativos (ALERTA!)
    if inactive_users:
        print("⚠️  USUÁRIOS INATIVOS (>{} dias):".format(INACTIVE_DAYS))
        print()
        for username, last_login, days in sorted(inactive_users, key=lambda x: x[2], reverse=True):
            print(f"  🔴 {username}")
            print(f"     Último login: {last_login.strftime('%d/%m/%Y %H:%M:%S')}")
            print(f"     Inativo há: {days} dias")
            print()
    else:
        print("✅ Nenhum usuário inativo encontrado")
        print()
    
    # Usuários que nunca fizeram login
    if never_logged:
        print("⚠️  USUÁRIOS QUE NUNCA FIZERAM LOGIN:")
        print()
        for username in never_logged:
            print(f"  ⚪ {username}")
        print()
    
    # Usuários ativos
    if active_users:
        print("✅ USUÁRIOS ATIVOS (últimos {} dias):".format(INACTIVE_DAYS))
        print()
        for username, last_login, days in sorted(active_users, key=lambda x: x[2]):
            print(f"  🟢 {username}")
            print(f"     Último login: {last_login.strftime('%d/%m/%Y %H:%M:%S')}")
            print(f"     ({days} dias atrás)")
            print()
    
    # Resumo
    print("=" * 60)
    print("📈 RESUMO:")
    print(f"  Total de usuários: {len(users)}")
    print(f"  ✅ Ativos: {len(active_users)}")
    print(f"  ⚠️  Inativos: {len(inactive_users)}")
    print(f"  ⚪ Nunca logaram: {len(never_logged)}")
    print("=" * 60)
    print()
    
    # Recomendações
    if inactive_users or never_logged:
        print("💡 RECOMENDAÇÕES:")
        print()
        if inactive_users:
            print("  Para usuários inativos:")
            print("  • Verificar se ainda precisam de acesso")
            print("  • Considerar desabilitar: sudo usermod -L <usuario>")
            print("  • Ou remover: sudo deluser <usuario>")
            print()
        if never_logged:
            print("  Para usuários que nunca logaram:")
            print("  • Podem ser contas criadas mas não utilizadas")
            print("  • Considerar remover se não forem necessárias")
            print()
    
    # Retornar código de saída
    if inactive_users:
        return 1  # Encontrou usuários inativos (alerta)
    else:
        return 0  # Tudo OK

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  Verificação interrompida pelo usuário")
        sys.exit(130)
    except Exception as e:
        print(f"\n❌ Erro fatal: {e}", file=sys.stderr)
        sys.exit(1)
