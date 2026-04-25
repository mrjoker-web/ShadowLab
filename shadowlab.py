#!/usr/bin/env python3
# ============================================================
#   Shadow Lab v1.0 — Lab Manager
#   Author  : Mr Joker | Shadow Suite
#   GitHub  : github.com/mrjoker-web
#
#   Uso:
#     python shadowlab.py start         # Inicia o lab
#     python shadowlab.py stop          # Para o lab
#     python shadowlab.py status        # Estado das máquinas
#     python shadowlab.py targets       # Lista alvos + IPs
#     python shadowlab.py hints <id>    # Dicas para um alvo
# ============================================================

import subprocess
import sys
import os
import json
from datetime import datetime

# ── Cores ────────────────────────────────────────────────────
class C:
    RED     = '\033[91m'
    GREEN   = '\033[92m'
    YELLOW  = '\033[93m'
    CYAN    = '\033[96m'
    MAGENTA = '\033[95m'
    WHITE   = '\033[97m'
    BOLD    = '\033[1m'
    DIM     = '\033[2m'
    RESET   = '\033[0m'

BANNER = f"""
{C.GREEN}{C.BOLD}
  ███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗      █████╗ ██████╗
  ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║     ██╔══██╗██╔══██╗
  ███████╗███████║███████║██║  ██║██║   ██║██║     ███████║██████╔╝
  ╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║     ██╔══██║██╔══██╗
  ███████║██║  ██║██║  ██║██████╔╝╚██████╔╝███████╗██║  ██║██████╔╝
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝╚══════╝╚═╝  ╚═╝╚═════╝
{C.YELLOW}
              Vulnerable Practice Environment v1.0
{C.RESET}{C.DIM}       by Mr Joker · Shadow Suite · github.com/mrjoker-web
       ⚠  Ambiente isolado — uso exclusivamente educacional{C.RESET}
"""

# ── Máquinas do lab ───────────────────────────────────────────
MACHINES = [
    # id, nome, ip, porta, nível, vector, vulns, descrição
    {
        "id":     "web-01",
        "name":   "Mutillidae II",
        "ip":     "10.10.0.10",
        "port":   8010,
        "level":  1,
        "vector": "WEB",
        "vulns":  ["SQLi", "XSS", "CSRF", "LFI", "Command Injection"],
        "desc":   "App web OWASP com múltiplas vulns — perfeito para começar",
        "url":    "http://localhost:8010",
        "flags":  ["flag{sqli_union_select}", "flag{xss_cookie_stolen}"],
        "hints": [
            "Tenta SQLi no campo de login: ' OR '1'='1",
            "O parâmetro 'page' na URL é vulnerável a LFI",
            "Usa o ShadowFuzz para descobrir paths ocultos",
            "Testa XSS reflectido no campo de pesquisa",
        ]
    },
    {
        "id":     "web-02",
        "name":   "DVWA",
        "ip":     "10.10.0.11",
        "port":   8011,
        "level":  1,
        "vector": "WEB",
        "vulns":  ["SQLi", "XSS", "CSRF", "File Upload", "Brute Force"],
        "desc":   "Damn Vulnerable Web App — dificuldade ajustável (Low/Medium/High)",
        "url":    "http://localhost:8011",
        "flags":  ["flag{dvwa_sqli_dump}", "flag{dvwa_upload_shell}"],
        "hints": [
            "Login default: admin / password",
            "Começa em 'Low' difficulty para entender a vuln",
            "No SQLi, tenta: 1' UNION SELECT user,password FROM users--",
            "No File Upload, tenta fazer upload de uma webshell PHP",
        ]
    },
    {
        "id":     "net-01",
        "name":   "FTP Vulnerable",
        "ip":     "10.10.0.20",
        "port":   8021,
        "level":  1,
        "vector": "NETWORK",
        "vulns":  ["Anonymous FTP", "Weak Credentials", "Banner Disclosure"],
        "desc":   "FTP com acesso anónimo e credenciais fracas",
        "url":    "ftp://localhost:8021",
        "flags":  ["flag{ftp_anon_access}", "flag{ftp_creds_shadow123}"],
        "hints": [
            "Usa o ShadowBanner: python shadow.py -t localhost --banner",
            "Tenta login anónimo: user=anonymous, pass=(qualquer email)",
            "As credenciais fracas são: shadow / shadow123",
            "Procura ficheiros sensíveis após o login",
        ]
    },
    {
        "id":     "net-02",
        "name":   "SSH Weak Creds",
        "ip":     "10.10.0.21",
        "port":   8022,
        "level":  1,
        "vector": "NETWORK",
        "vulns":  ["Weak SSH Credentials", "Banner Grabbing"],
        "desc":   "SSH com credenciais fracas — brute force e banner",
        "url":    "ssh://localhost:8022",
        "flags":  ["flag{ssh_root_access}"],
        "hints": [
            "Usa ShadowBanner para ver a versão do SSH",
            "Tenta credenciais: root:root, admin:admin, ubuntu:ubuntu",
            "Usa hydra para brute force: hydra -l root -P rockyou.txt ssh://localhost:8022",
        ]
    },
    {
        "id":     "web-03",
        "name":   "OWASP Juice Shop",
        "ip":     "10.10.0.30",
        "port":   8030,
        "level":  2,
        "vector": "WEB",
        "vulns":  ["XSS", "SQLi", "IDOR", "JWT Attacks", "SSRF", "XXE", "Broken Auth"],
        "desc":   "100+ desafios OWASP — nível intermédio a avançado",
        "url":    "http://localhost:8030",
        "flags":  ["flag{jwt_none_alg}", "flag{idor_another_user}", "flag{ssrf_internal}"],
        "hints": [
            "Inspeciona os requests da API no Burp Suite",
            "O JWT usa o algoritmo 'none' — consegues fazer bypass?",
            "Testa IDOR nos endpoints /api/Users/<id>",
            "Usa o ShadowFuzz para encontrar endpoints escondidos da API",
            "Procura por comentários no código fonte — há segredos escondidos",
        ]
    },
    {
        "id":     "net-03",
        "name":   "Redis No Auth",
        "ip":     "10.10.0.40",
        "port":   8379,
        "level":  2,
        "vector": "NETWORK",
        "vulns":  ["Unauthenticated Redis", "RCE via config", "Data Exposure"],
        "desc":   "Redis exposto sem autenticação",
        "url":    "redis://localhost:8379",
        "flags":  ["flag{redis_noauth_data}", "flag{redis_rce_cron}"],
        "hints": [
            "Usa o ShadowScanner: python shadowscanner.py localhost -p 6379",
            "Conecta directamente: redis-cli -h localhost -p 8379",
            "Corre INFO e KEYS * para ver os dados expostos",
            "Avançado: usa CONFIG SET para escrever ficheiros no disco",
        ]
    },
    {
        "id":     "net-04",
        "name":   "MongoDB No Auth",
        "ip":     "10.10.0.42",
        "port":   27117,
        "level":  2,
        "vector": "NETWORK",
        "vulns":  ["Unauthenticated MongoDB", "Data Exposure", "NoSQLi"],
        "desc":   "MongoDB exposto sem autenticação",
        "url":    "mongodb://localhost:27117",
        "flags":  ["flag{mongodb_users_dump}"],
        "hints": [
            "Conecta: mongosh --host localhost --port 27117",
            "Lista bases de dados: show dbs",
            "Procura por colecções com dados sensíveis",
            "Usa o ShadowScanner para detectar o serviço primeiro",
        ]
    },
    {
        "id":     "web-05",
        "name":   "Vulnerable API",
        "ip":     "10.10.0.50",
        "port":   8050,
        "level":  3,
        "vector": "WEB",
        "vulns":  ["IDOR", "JWT None Algorithm", "Mass Assignment", "BOLA", "SSRF"],
        "desc":   "REST API custom com OWASP API Top 10",
        "url":    "http://localhost:8050",
        "flags":  ["flag{api_idor_v2}", "flag{jwt_alg_confusion}", "flag{mass_assign_admin}"],
        "hints": [
            "Lê a documentação da API em /api/docs",
            "Testa todos os endpoints com diferentes user IDs",
            "O JWT pode ser manipulado — tenta alterar o campo 'role'",
            "Mass assignment: envia campos extra no POST /api/users",
            "Usa o ShadowFuzz para descobrir endpoints não documentados",
        ]
    },
    {
        "id":     "web-06",
        "name":   "LFI to RCE Chain",
        "ip":     "10.10.0.51",
        "port":   8051,
        "level":  3,
        "vector": "WEB",
        "vulns":  ["LFI", "Log Poisoning", "RCE", "Path Traversal"],
        "desc":   "Cadeia completa: LFI → Log Poisoning → RCE",
        "url":    "http://localhost:8051",
        "flags":  ["flag{lfi_passwd_leak}", "flag{log_poison_rce}"],
        "hints": [
            "Passo 1: encontra o parâmetro vulnerável a LFI",
            "Passo 2: lê /etc/passwd com path traversal: ../../../../etc/passwd",
            "Passo 3: inclui o ficheiro de log do Apache",
            "Passo 4: envia um User-Agent com código PHP malicioso",
            "Passo 5: inclui o log novamente para executar o código",
        ]
    },
    {
        "id":     "android-01",
        "name":   "Android Backend API",
        "ip":     "10.10.0.70",
        "port":   8070,
        "level":  2,
        "vector": "ANDROID",
        "vulns":  ["Insecure API", "Hardcoded Secrets", "Broken Auth", "Sensitive Data"],
        "desc":   "Backend de app Android — usar com ShadowDroid",
        "url":    "http://localhost:8070",
        "flags":  ["flag{hardcoded_api_key}", "flag{android_idor_user}"],
        "hints": [
            "Usa o ShadowDroid para analisar a app cliente",
            "Procura por hardcoded secrets nos ficheiros APK",
            "Testa os endpoints da API sem autenticação",
            "Verifica se existe IDOR nos IDs de utilizador",
        ]
    },
]

LEVEL_COLOR = {1: C.GREEN, 2: C.YELLOW, 3: C.RED}
LEVEL_NAME  = {1: "INICIANTE", 2: "INTERMÉDIO", 3: "AVANÇADO"}
VECTOR_COLOR = {"WEB": C.CYAN, "NETWORK": C.MAGENTA, "ANDROID": C.GREEN}

def separator(title=''):
    if title:
        pad = (60 - len(title) - 2) // 2
        print(f'\n{C.DIM}{"─"*pad} {C.BOLD}{C.WHITE}{title}{C.RESET}{C.DIM} {"─"*pad}{C.RESET}')
    else:
        print(f'{C.DIM}{"─"*60}{C.RESET}')

def log(msg, level='info'):
    prefix = {
        'info': f'{C.CYAN}[*]{C.RESET}',
        'ok':   f'{C.GREEN}[+]{C.RESET}',
        'warn': f'{C.YELLOW}[!]{C.RESET}',
        'err':  f'{C.RED}[-]{C.RESET}',
    }.get(level, '[?]')
    print(f'  {prefix} {msg}')

# ── Docker commands ───────────────────────────────────────────
def docker_compose(cmd):
    result = subprocess.run(
        ['docker-compose'] + cmd,
        capture_output=True, text=True
    )
    return result.returncode, result.stdout, result.stderr

def check_docker():
    try:
        subprocess.run(['docker', 'info'], capture_output=True, check=True)
        return True
    except Exception:
        return False

# ── Commands ──────────────────────────────────────────────────
def cmd_start(args):
    separator('INICIANDO SHADOW LAB')
    if not check_docker():
        log('Docker não encontrado. Instala Docker e Docker Compose.', 'err')
        sys.exit(1)

    log('A iniciar todas as máquinas...', 'info')
    code, out, err = docker_compose(['up', '-d', '--build'])

    if code == 0:
        log('Shadow Lab iniciado com sucesso!', 'ok')
        print()
        cmd_targets(args)
    else:
        log(f'Erro ao iniciar: {err[:200]}', 'err')

def cmd_stop(args):
    separator('A PARAR SHADOW LAB')
    log('A parar todas as máquinas...', 'info')
    code, out, err = docker_compose(['down'])
    if code == 0:
        log('Shadow Lab parado.', 'ok')
    else:
        log(f'Erro: {err[:200]}', 'err')

def cmd_status(args):
    separator('STATUS DAS MÁQUINAS')
    code, out, err = docker_compose(['ps'])
    if out:
        print(f'{C.DIM}{out}{C.RESET}')
    else:
        log('Nenhuma máquina em execução.', 'warn')

def cmd_targets(args):
    separator('ALVOS DISPONÍVEIS')

    for level in [1, 2, 3]:
        machines = [m for m in MACHINES if m['level'] == level or
                   (isinstance(m['level'], str) and str(level) in m['level'])]
        if not machines:
            continue

        lc = LEVEL_COLOR.get(level, C.RESET)
        ln = LEVEL_NAME.get(level, '')
        print(f'\n  {lc}{C.BOLD}● NÍVEL {level} — {ln}{C.RESET}')
        separator()

        for m in machines:
            vc   = VECTOR_COLOR.get(m['vector'], C.RESET)
            vulns = ', '.join(m['vulns'][:3])
            if len(m['vulns']) > 3:
                vulns += f' +{len(m["vulns"])-3}'

            print(f'  {C.BOLD}[{m["id"]}]{C.RESET}  {C.WHITE}{m["name"]}{C.RESET}')
            print(f'         {C.DIM}URL   :{C.RESET} {C.CYAN}{m["url"]}{C.RESET}')
            print(f'         {C.DIM}Vector:{C.RESET} {vc}{m["vector"]}{C.RESET}')
            print(f'         {C.DIM}Vulns :{C.RESET} {C.YELLOW}{vulns}{C.RESET}')
            print(f'         {C.DIM}{m["desc"]}{C.RESET}')
            print()

    print(f'  {C.DIM}Dashboard: http://localhost:8080{C.RESET}')
    print(f'  {C.DIM}Usa "python shadowlab.py hints <id>" para dicas{C.RESET}\n')

def cmd_hints(args):
    if len(args) < 2:
        log('Uso: python shadowlab.py hints <machine-id>', 'err')
        log('Exemplo: python shadowlab.py hints web-01', 'info')
        return

    machine_id = args[1].lower()
    machine    = next((m for m in MACHINES if m['id'] == machine_id), None)

    if not machine:
        log(f'Máquina "{machine_id}" não encontrada.', 'err')
        log(f'IDs disponíveis: {", ".join(m["id"] for m in MACHINES)}', 'info')
        return

    lc = LEVEL_COLOR.get(machine['level'], C.RESET)
    vc = VECTOR_COLOR.get(machine['vector'], C.RESET)

    separator(f'HINTS — {machine["name"].upper()}')
    print(f'\n  {C.BOLD}Máquina :{C.RESET} {machine["name"]}')
    print(f'  {C.BOLD}URL     :{C.RESET} {C.CYAN}{machine["url"]}{C.RESET}')
    print(f'  {C.BOLD}Nível   :{C.RESET} {lc}{LEVEL_NAME.get(machine["level"], machine["level"])}{C.RESET}')
    print(f'  {C.BOLD}Vector  :{C.RESET} {vc}{machine["vector"]}{C.RESET}')
    print(f'  {C.BOLD}Vulns   :{C.RESET} {C.YELLOW}{", ".join(machine["vulns"])}{C.RESET}')
    print(f'\n  {C.DIM}{machine["desc"]}{C.RESET}\n')

    separator('DICAS')
    for i, hint in enumerate(machine['hints'], 1):
        print(f'  {C.CYAN}{i}.{C.RESET} {hint}')

    separator('SHADOW SUITE — COMANDOS SUGERIDOS')
    if machine['vector'] == 'WEB':
        print(f'  {C.DIM}# Scan inicial{C.RESET}')
        print(f'  {C.GREEN}python shadow.py -t localhost --scan --banner{C.RESET}')
        print(f'  {C.DIM}# Directory fuzzing{C.RESET}')
        print(f'  {C.GREEN}python shadow.py -t localhost:{machine["port"]} --fuzz{C.RESET}')
    elif machine['vector'] == 'NETWORK':
        print(f'  {C.DIM}# Network scan{C.RESET}')
        print(f'  {C.GREEN}python shadowscanner.py localhost -p {machine["port"]} --top-ports{C.RESET}')
        print(f'  {C.DIM}# Banner grabbing{C.RESET}')
        print(f'  {C.GREEN}python shadow.py -t localhost --banner{C.RESET}')
    elif machine['vector'] == 'ANDROID':
        print(f'  {C.DIM}# Android audit{C.RESET}')
        print(f'  {C.GREEN}python shadowdroid.py --all -o lab_report.json{C.RESET}')
        print(f'  {C.DIM}# API analysis{C.RESET}')
        print(f'  {C.GREEN}python shadow.py -t localhost:{machine["port"]} --scan --fuzz{C.RESET}')
    print()

def cmd_info(args):
    separator('SHADOW LAB — INFO')
    total    = len(MACHINES)
    by_level = {1: 0, 2: 0, 3: 0}
    by_vec   = {}
    for m in MACHINES:
        lvl = m['level'] if isinstance(m['level'], int) else 2
        by_level[lvl] = by_level.get(lvl, 0) + 1
        by_vec[m['vector']] = by_vec.get(m['vector'], 0) + 1

    print(f'\n  {C.BOLD}Total de máquinas :{C.RESET} {C.GREEN}{total}{C.RESET}')
    print(f'  {C.BOLD}Nível 1 (Iniciante):{C.RESET} {C.GREEN}{by_level[1]}{C.RESET} máquinas')
    print(f'  {C.BOLD}Nível 2 (Intermédio):{C.RESET} {C.YELLOW}{by_level[2]}{C.RESET} máquinas')
    print(f'  {C.BOLD}Nível 3 (Avançado):{C.RESET} {C.RED}{by_level[3]}{C.RESET} máquinas')
    print()
    for vec, count in by_vec.items():
        vc = VECTOR_COLOR.get(vec, C.RESET)
        print(f'  {C.BOLD}{vc}{vec:<10}{C.RESET} {count} máquinas')
    print(f'\n  {C.DIM}Dashboard: http://localhost:8080{C.RESET}\n')

def cmd_help():
    separator('SHADOW LAB — COMANDOS')
    cmds = [
        ('start',        'Inicia todas as máquinas do lab'),
        ('stop',         'Para todas as máquinas'),
        ('status',       'Mostra o estado dos containers'),
        ('targets',      'Lista todos os alvos com IPs e portas'),
        ('hints <id>',   'Dicas e comandos para uma máquina específica'),
        ('info',         'Resumo do lab (total, níveis, vetores)'),
        ('help',         'Mostrar esta ajuda'),
    ]
    for cmd, desc in cmds:
        print(f'  {C.CYAN}python shadowlab.py {cmd:<20}{C.RESET} {C.DIM}{desc}{C.RESET}')

    print(f'\n  {C.DIM}Exemplos:{C.RESET}')
    print(f'  {C.GREEN}python shadowlab.py start{C.RESET}')
    print(f'  {C.GREEN}python shadowlab.py targets{C.RESET}')
    print(f'  {C.GREEN}python shadowlab.py hints web-03{C.RESET}\n')

# ── Main ──────────────────────────────────────────────────────
def main():
    print(BANNER)

    args = sys.argv[1:]
    cmd  = args[0] if args else 'help'

    commands = {
        'start':   cmd_start,
        'stop':    cmd_stop,
        'status':  cmd_status,
        'targets': cmd_targets,
        'hints':   cmd_hints,
        'info':    cmd_info,
    }

    if cmd == 'help' or cmd not in commands:
        cmd_help()
    else:
        commands[cmd](args)

if __name__ == '__main__':
    main()
