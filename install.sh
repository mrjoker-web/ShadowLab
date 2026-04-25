#!/bin/bash
# ============================================================
#   Shadow Lab v1.0 — Auto Installer
#   Author  : Mr Joker | Shadow Suite
#   GitHub  : github.com/mrjoker-web/ShadowLab
#
#   Uso     : bash install.sh
#   Requisito: Ubuntu 20.04+ numa VM VirtualBox
#
#   ⚠  APENAS para uso em VMs isoladas
#   ⚠  NUNCA instalar em sistemas de produção
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

log_ok()   { echo -e "  ${GREEN}[+]${RESET} $1"; }
log_info() { echo -e "  ${CYAN}[*]${RESET} $1"; }
log_warn() { echo -e "  ${YELLOW}[!]${RESET} $1"; }
log_err()  { echo -e "  ${RED}[-]${RESET} $1"; }
log_sect() {
    echo ""
    echo -e "  ${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${MAGENTA}${BOLD}  $1${RESET}"
    echo -e "  ${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

SHADOWLAB_DIR="/opt/shadowlab"
SERVICES_DIR="$SHADOWLAB_DIR/services"
WEB_DIR="$SHADOWLAB_DIR/web"
LOG_FILE="$SHADOWLAB_DIR/install.log"

# ── Banner ────────────────────────────────────────────────────
clear
echo -e "${GREEN}${BOLD}"
cat << 'EOF'
  ███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗      █████╗ ██████╗
  ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║     ██╔══██╗██╔══██╗
  ███████╗███████║███████║██║  ██║██║   ██║██║     ███████║██████╔╝
  ╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║     ██╔══██║██╔══██╗
  ███████║██║  ██║██║  ██║██████╔╝╚██████╔╝███████╗██║  ██║██████╔╝
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝╚══════╝╚═╝  ╚═╝╚═════╝
EOF
echo -e "${RESET}"
echo -e "${CYAN}  Vulnerable Practice Environment — Auto Installer v1.0${RESET}"
echo -e "${CYAN}  by Mr Joker · Shadow Suite · github.com/mrjoker-web${RESET}"
echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${YELLOW}[!]${RESET} Este script instala serviços VULNERÁVEIS."
echo -e "  ${YELLOW}[!]${RESET} Usa APENAS numa VM isolada do VirtualBox."
echo -e "  ${YELLOW}[!]${RESET} NUNCA em sistemas de produção ou redes públicas."
echo ""
echo -ne "  Continuar? [s/N] "
read -r confirm
[[ "$confirm" != "s" && "$confirm" != "S" ]] && echo "  Cancelado." && exit 0

# ── Verificações ──────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    log_err "Corre como root: sudo bash install.sh"
    exit 1
fi

if ! command -v apt &> /dev/null; then
    log_err "Apenas Ubuntu/Debian suportado."
    exit 1
fi

# ── Preparar diretórios ───────────────────────────────────────
mkdir -p "$SHADOWLAB_DIR" "$SERVICES_DIR" "$WEB_DIR"
touch "$LOG_FILE"
log_ok "Diretório base: $SHADOWLAB_DIR"

# ════════════════════════════════════════════════════════════
# STEP 1 — SISTEMA BASE
# ════════════════════════════════════════════════════════════
log_sect "STEP 1 — SISTEMA BASE"

log_info "A atualizar sistema..."
apt update -y >> "$LOG_FILE" 2>&1
apt upgrade -y >> "$LOG_FILE" 2>&1
log_ok "Sistema atualizado!"

log_info "A instalar dependências base..."
apt install -y \
    git curl wget python3 python3-pip \
    apache2 php php-mysqli libapache2-mod-php \
    mysql-server \
    openssh-server \
    vsftpd \
    redis-server \
    nodejs npm \
    net-tools nmap \
    ufw \
    >> "$LOG_FILE" 2>&1
log_ok "Dependências instaladas!"

pip3 install flask flask-sqlalchemy flask-jwt-extended requests colorama >> "$LOG_FILE" 2>&1
log_ok "Python packages instalados!"

# ════════════════════════════════════════════════════════════
# STEP 2 — SSH SEGURO PARA ACESSO REMOTO (Termux)
# ════════════════════════════════════════════════════════════
log_sect "STEP 2 — SSH (Acesso via Termux)"

log_info "A configurar SSH..."
cat > /etc/ssh/sshd_config.d/shadowlab.conf << 'SSHCFG'
# Shadow Lab SSH config
Port 22
PermitRootLogin no
PasswordAuthentication yes
MaxAuthTries 5
Banner /etc/ssh/shadowlab_banner
SSHCFG

cat > /etc/ssh/shadowlab_banner << 'BANNER'

  ╔══════════════════════════════════════════╗
  ║       SHADOW LAB — Acesso Autorizado     ║
  ║   Ambiente de prática — Uso educacional  ║
  ╚══════════════════════════════════════════╝

BANNER

# Criar user dedicado para o lab
if ! id "shadowlab" &>/dev/null; then
    useradd -m -s /bin/bash shadowlab
    echo "shadowlab:ShadowLab2024!" | chpasswd
    log_ok "Utilizador 'shadowlab' criado — pass: ShadowLab2024!"
fi

systemctl restart ssh >> "$LOG_FILE" 2>&1
log_ok "SSH configurado na porta 22!"
log_info "Acesso Termux: ssh shadowlab@<IP_DA_VM>"

# ════════════════════════════════════════════════════════════
# STEP 3 — NÍVEL 1: SERVIÇOS VULNERÁVEIS BÁSICOS
# ════════════════════════════════════════════════════════════
log_sect "STEP 3 — NÍVEL 1 (Iniciante)"

# ── 3.1 FTP anónimo ──────────────────────────────────────────
log_info "A configurar FTP vulnerável (porta 8021)..."
cat > /etc/vsftpd_shadowlab.conf << 'FTPCFG'
listen=YES
listen_port=8021
anonymous_enable=YES
anon_root=/opt/shadowlab/services/ftp/public
local_enable=YES
write_enable=NO
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
ftpd_banner=220 Shadow FTP Server v2.1 — Welcome
local_max_rate=1000000
FTPCFG

mkdir -p /opt/shadowlab/services/ftp/public
cat > /opt/shadowlab/services/ftp/public/README.txt << 'EOF'
Shadow Lab — FTP Vulnerable
===========================
Estás no servidor FTP público.

Tarefa: encontra os ficheiros sensíveis neste servidor.
Dica: explora bem os diretórios...
EOF

mkdir -p /opt/shadowlab/services/ftp/public/backups
cat > /opt/shadowlab/services/ftp/public/backups/credentials.txt << 'EOF'
# Backup de credenciais — NÃO DEIXAR AQUI!
db_user=admin
db_pass=Admin@2024
ftp_user=shadow
ftp_pass=shadow123
flag{ftp_anon_backup_found}
EOF

useradd -m -s /bin/bash ftpuser 2>/dev/null
echo "ftpuser:shadow123" | chpasswd
vsftpd /etc/vsftpd_shadowlab.conf &
log_ok "FTP vulnerável a correr na porta 8021!"

# ── 3.2 SSH credenciais fracas ───────────────────────────────
log_info "A criar conta SSH com credenciais fracas (porta 8022)..."
if ! id "weakuser" &>/dev/null; then
    useradd -m -s /bin/bash weakuser
    echo "weakuser:password123" | chpasswd
fi

# SSH numa porta separada para o lab
cat >> /etc/ssh/sshd_config << 'EOF'

# Shadow Lab — SSH weak creds port
Port 8022
EOF
systemctl restart ssh >> "$LOG_FILE" 2>&1
log_ok "SSH fraco na porta 8022 (user: weakuser / pass: password123)!"

# ── 3.3 DVWA ─────────────────────────────────────────────────
log_info "A instalar DVWA (porta 8010)..."
if [ ! -d "/opt/shadowlab/web/dvwa" ]; then
    git clone https://github.com/digininja/DVWA.git /opt/shadowlab/web/dvwa >> "$LOG_FILE" 2>&1
fi

cp /opt/shadowlab/web/dvwa/config/config.inc.php.dist \
   /opt/shadowlab/web/dvwa/config/config.inc.php

# MySQL para DVWA
mysql -e "CREATE DATABASE IF NOT EXISTS dvwa;" >> "$LOG_FILE" 2>&1
mysql -e "CREATE USER IF NOT EXISTS 'dvwa'@'localhost' IDENTIFIED BY 'dvwa_pass';" >> "$LOG_FILE" 2>&1
mysql -e "GRANT ALL ON dvwa.* TO 'dvwa'@'localhost';" >> "$LOG_FILE" 2>&1
mysql -e "FLUSH PRIVILEGES;" >> "$LOG_FILE" 2>&1

sed -i "s/\$_DVWA\[ 'db_password' \] = 'p\@ssw0rd';/\$_DVWA[ 'db_password' ] = 'dvwa_pass';/" \
    /opt/shadowlab/web/dvwa/config/config.inc.php

cat > /etc/apache2/sites-available/dvwa.conf << 'APACHECFG'
<VirtualHost *:8010>
    DocumentRoot /opt/shadowlab/web/dvwa
    <Directory /opt/shadowlab/web/dvwa>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
APACHECFG

chown -R www-data:www-data /opt/shadowlab/web/dvwa
a2ensite dvwa.conf >> "$LOG_FILE" 2>&1
a2enmod rewrite >> "$LOG_FILE" 2>&1
log_ok "DVWA instalado na porta 8010!"

# ════════════════════════════════════════════════════════════
# STEP 4 — NÍVEL 2: SERVIÇOS VULNERÁVEIS INTERMÉDIOS
# ════════════════════════════════════════════════════════════
log_sect "STEP 4 — NÍVEL 2 (Intermédio)"

# ── 4.1 Redis sem autenticação ───────────────────────────────
log_info "A configurar Redis sem autenticação (porta 8379)..."
cat > /etc/redis/redis_shadowlab.conf << 'REDISCFG'
port 8379
bind 0.0.0.0
protected-mode no
loglevel notice
logfile /var/log/redis/shadowlab.log
requirepass ""
REDISCFG

redis-server /etc/redis/redis_shadowlab.conf --daemonize yes >> "$LOG_FILE" 2>&1

# Inserir dados sensíveis para descoberta
sleep 1
redis-cli -p 8379 SET "user:1:email" "admin@shadowlab.com" >> "$LOG_FILE" 2>&1
redis-cli -p 8379 SET "user:1:pass" "SuperSecret2024" >> "$LOG_FILE" 2>&1
redis-cli -p 8379 SET "api_key" "sk-shadow-1337-deadbeef-cafe" >> "$LOG_FILE" 2>&1
redis-cli -p 8379 SET "flag" "flag{redis_noauth_data_exposed}" >> "$LOG_FILE" 2>&1
log_ok "Redis sem auth na porta 8379!"

# ── 4.2 API REST vulnerável (Flask) ──────────────────────────
log_info "A instalar Vulnerable REST API (porta 8050)..."
mkdir -p /opt/shadowlab/services/api

cat > /opt/shadowlab/services/api/app.py << 'APIPY'
#!/usr/bin/env python3
# Shadow Lab — Vulnerable API (Nível 2-3)
# Vulns: IDOR, JWT None Alg, Mass Assignment, Broken Auth

from flask import Flask, request, jsonify
import jwt, json, os, sqlite3
from datetime import datetime, timedelta

app = Flask(__name__)
SECRET = "shadow_secret_2024"
DB     = "/opt/shadowlab/services/api/users.db"

def get_db():
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    conn.execute("""CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY, username TEXT, password TEXT,
        email TEXT, role TEXT DEFAULT 'user', balance REAL DEFAULT 0
    )""")
    users = [
        (1, 'admin',   'Admin@2024!', 'admin@lab.com',   'admin',  9999.99),
        (2, 'mrjoker', 'shadow123',   'joker@lab.com',   'user',   100.00),
        (3, 'victim',  'password',    'victim@lab.com',  'user',   50.00),
    ]
    for u in users:
        try:
            conn.execute("INSERT INTO users VALUES (?,?,?,?,?,?)", u)
        except: pass
    conn.commit()
    conn.close()

@app.route('/')
def index():
    return jsonify({
        "name": "Shadow Lab Vulnerable API",
        "version": "1.0",
        "docs": "/api/docs",
        "flag_hint": "Encontra o endpoint escondido..."
    })

@app.route('/api/docs')
def docs():
    return jsonify({
        "endpoints": {
            "POST /api/login":        "Login — retorna JWT",
            "GET  /api/users/<id>":   "Perfil de utilizador",
            "PUT  /api/users/<id>":   "Actualizar perfil",
            "GET  /api/admin/users":  "Lista todos os users (admin)",
            "GET  /api/flag":         "Flag — só para admins",
        }
    })

# VULN: Sem rate limiting, credenciais em texto
@app.route('/api/login', methods=['POST'])
def login():
    data = request.json or {}
    username = data.get('username', '')
    password = data.get('password', '')
    conn = get_db()
    # VULN: SQLi possível aqui
    user = conn.execute(
        f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"
    ).fetchone()
    conn.close()
    if not user:
        return jsonify({"error": "Invalid credentials"}), 401
    token = jwt.encode({
        "id": user["id"], "role": user["role"],
        "exp": datetime.utcnow() + timedelta(hours=1)
    }, SECRET, algorithm="HS256")
    return jsonify({"token": token, "user_id": user["id"]})

def get_token_data():
    auth = request.headers.get('Authorization', '')
    if not auth.startswith('Bearer '):
        return None
    token = auth.split(' ')[1]
    try:
        # VULN: aceita algoritmo 'none'
        return jwt.decode(token, options={"verify_signature": False})
    except:
        return None

# VULN: IDOR — qualquer user pode ver qualquer perfil
@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    token_data = get_token_data()
    if not token_data:
        return jsonify({"error": "Unauthorized"}), 401
    conn = get_db()
    user = conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    conn.close()
    if not user:
        return jsonify({"error": "Not found"}), 404
    # VULN: expõe password
    return jsonify(dict(user))

# VULN: Mass Assignment — aceita 'role' no body
@app.route('/api/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    token_data = get_token_data()
    if not token_data:
        return jsonify({"error": "Unauthorized"}), 401
    data = request.json or {}
    # VULN: não filtra campos — permite mass assignment
    allowed = ['username', 'email', 'password', 'role', 'balance']
    updates = {k: v for k, v in data.items() if k in allowed}
    if not updates:
        return jsonify({"error": "No data"}), 400
    fields = ', '.join(f"{k}=?" for k in updates)
    values = list(updates.values()) + [user_id]
    conn = get_db()
    conn.execute(f"UPDATE users SET {fields} WHERE id=?", values)
    conn.commit()
    conn.close()
    return jsonify({"message": "Updated", "fields": list(updates.keys())})

@app.route('/api/admin/users')
def admin_users():
    token_data = get_token_data()
    if not token_data or token_data.get('role') != 'admin':
        return jsonify({"error": "Forbidden"}), 403
    conn = get_db()
    users = conn.execute("SELECT * FROM users").fetchall()
    conn.close()
    return jsonify([dict(u) for u in users])

# VULN: endpoint escondido sem auth
@app.route('/api/v0/debug')
def debug():
    return jsonify({
        "flag": "flag{hidden_debug_endpoint_found}",
        "secret": SECRET,
        "db_path": DB,
        "env": dict(os.environ)
    })

@app.route('/api/flag')
def flag():
    token_data = get_token_data()
    if not token_data:
        return jsonify({"error": "Unauthorized"}), 401
    if token_data.get('role') == 'admin':
        return jsonify({"flag": "flag{api_admin_access_granted}"})
    return jsonify({"error": "Admins only"}), 403

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=8050, debug=False)
APIPY

cat > /etc/systemd/system/shadowlab-api.service << 'SVCAPI'
[Unit]
Description=Shadow Lab Vulnerable API
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/shadowlab/services/api/app.py
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
SVCAPI

systemctl daemon-reload >> "$LOG_FILE" 2>&1
systemctl enable shadowlab-api >> "$LOG_FILE" 2>&1
systemctl start shadowlab-api >> "$LOG_FILE" 2>&1
log_ok "Vulnerable API na porta 8050!"

# ════════════════════════════════════════════════════════════
# STEP 5 — NÍVEL 3: LFI → RCE CHAIN
# ════════════════════════════════════════════════════════════
log_sect "STEP 5 — NÍVEL 3 (Avançado)"

log_info "A instalar app LFI → RCE (porta 8051)..."
mkdir -p /opt/shadowlab/web/lfi
cat > /opt/shadowlab/web/lfi/index.php << 'LFIPHP'
<?php
// Shadow Lab — LFI to RCE Challenge
// Nível: Avançado | Vulns: LFI, Log Poisoning, Path Traversal

$page = $_GET['page'] ?? 'home';

// VULN: LFI sem sanitização
$page = str_replace('../', '', $page); // filtro fraco — bypassável
$file = "pages/" . $page . ".php";

echo "<html><head><title>Shadow Lab — LFI Challenge</title></head><body>";
echo "<h1>Shadow Lab Portal</h1>";
echo "<p>Page: " . htmlspecialchars($page) . "</p>";
echo "<hr>";

if (file_exists($file)) {
    include($file);
} else {
    // VULN: inclui path controlado pelo utilizador
    @include($page);
    echo "<p>Page not found.</p>";
}
echo "</body></html>";
?>
LFIPHP

mkdir -p /opt/shadowlab/web/lfi/pages
echo "<?php echo '<h2>Home Page</h2><p>Bem-vindo ao Shadow Lab Portal!</p>'; ?>" \
    > /opt/shadowlab/web/lfi/pages/home.php
echo "<?php echo '<h2>About</h2><p>flag{lfi_path_traversal_works}</p>'; ?>" \
    > /opt/shadowlab/web/lfi/pages/secret.php

cat > /etc/apache2/sites-available/lfi.conf << 'LFICFG'
<VirtualHost *:8051>
    DocumentRoot /opt/shadowlab/web/lfi
    <Directory /opt/shadowlab/web/lfi>
        AllowOverride All
        Require all granted
        php_flag display_errors on
    </Directory>
    CustomLog /var/log/apache2/lfi_access.log combined
</VirtualHost>
LFICFG

a2ensite lfi.conf >> "$LOG_FILE" 2>&1
log_ok "LFI → RCE chain na porta 8051!"

# ════════════════════════════════════════════════════════════
# STEP 6 — APACHE + PORTAS
# ════════════════════════════════════════════════════════════
log_sect "STEP 6 — APACHE & FIREWALL"

# Activar portas extra no Apache
cat >> /etc/apache2/ports.conf << 'EOF'
Listen 8010
Listen 8051
EOF

systemctl restart apache2 >> "$LOG_FILE" 2>&1
log_ok "Apache reiniciado!"

# Firewall — abrir portas do lab
log_info "A configurar firewall..."
ufw --force enable >> "$LOG_FILE" 2>&1
ufw allow 22   >> "$LOG_FILE" 2>&1   # SSH seguro
ufw allow 8010 >> "$LOG_FILE" 2>&1   # DVWA
ufw allow 8021 >> "$LOG_FILE" 2>&1   # FTP
ufw allow 8022 >> "$LOG_FILE" 2>&1   # SSH fraco
ufw allow 8050 >> "$LOG_FILE" 2>&1   # API
ufw allow 8051 >> "$LOG_FILE" 2>&1   # LFI
ufw allow 8079 >> "$LOG_FILE" 2>&1   # Dashboard
ufw allow 8379 >> "$LOG_FILE" 2>&1   # Redis
log_ok "Firewall configurada!"

# ════════════════════════════════════════════════════════════
# STEP 7 — DASHBOARD WEB
# ════════════════════════════════════════════════════════════
log_sect "STEP 7 — SHADOW LAB DASHBOARD"

log_info "A instalar dashboard..."
mkdir -p /opt/shadowlab/dashboard

cat > /opt/shadowlab/dashboard/app.py << 'DASHPY'
#!/usr/bin/env python3
# Shadow Lab Dashboard
from flask import Flask, render_template_string
import subprocess, socket

app = Flask(__name__)

MACHINES = [
    {"id":"web-01","name":"DVWA","port":8010,"level":1,"vector":"WEB",
     "vulns":"SQLi, XSS, CSRF, File Upload","url":"http://{ip}:8010"},
    {"id":"net-01","name":"FTP Vulnerable","port":8021,"level":1,"vector":"NETWORK",
     "vulns":"Anonymous FTP, Weak Creds","url":"ftp://{ip}:8021"},
    {"id":"net-02","name":"SSH Weak Creds","port":8022,"level":1,"vector":"NETWORK",
     "vulns":"Weak SSH, Banner Grabbing","url":"ssh://{ip}:8022"},
    {"id":"net-03","name":"Redis No Auth","port":8379,"level":2,"vector":"NETWORK",
     "vulns":"Unauthenticated Redis, Data Exposure","url":"redis://{ip}:8379"},
    {"id":"web-02","name":"Vulnerable API","port":8050,"level":2,"vector":"WEB",
     "vulns":"IDOR, SQLi, Mass Assignment, JWT","url":"http://{ip}:8050"},
    {"id":"web-03","name":"LFI → RCE Chain","port":8051,"level":3,"vector":"WEB",
     "vulns":"LFI, Log Poisoning, RCE","url":"http://{ip}:8051"},
]

def get_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except: return "localhost"

def check_port(port):
    try:
        s = socket.socket()
        s.settimeout(1)
        s.connect(("localhost", port))
        s.close()
        return True
    except: return False

TEMPLATE = """
<!DOCTYPE html><html><head>
<title>Shadow Lab</title>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { background: #0d0d0d; color: #e0e0e0; font-family: 'Courier New', monospace; }
.header { background: #111; border-bottom: 2px solid #00ff00;
          padding: 20px 40px; display: flex; align-items: center; gap: 20px; }
.header h1 { color: #00ff00; font-size: 1.8rem; letter-spacing: 2px; }
.header p  { color: #666; font-size: 0.8rem; margin-top: 4px; }
.badge { background: #00ff0020; border: 1px solid #00ff00;
         color: #00ff00; padding: 4px 12px; border-radius: 20px;
         font-size: 0.75rem; margin-left: auto; }
.container { max-width: 1100px; margin: 40px auto; padding: 0 20px; }
.section-title { color: #666; font-size: 0.7rem; letter-spacing: 3px;
                 text-transform: uppercase; margin-bottom: 16px;
                 border-bottom: 1px solid #1a1a1a; padding-bottom: 8px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
        gap: 16px; margin-bottom: 40px; }
.card { background: #141414; border: 1px solid #222; border-radius: 8px;
        padding: 20px; position: relative; transition: border-color 0.2s; }
.card:hover { border-color: #333; }
.card-header { display: flex; justify-content: space-between;
               align-items: flex-start; margin-bottom: 12px; }
.card-title { font-size: 1rem; font-weight: bold; color: #fff; }
.card-id { font-size: 0.7rem; color: #444; }
.level { display: inline-block; padding: 2px 10px; border-radius: 10px;
         font-size: 0.7rem; font-weight: bold; margin-bottom: 10px; }
.level-1 { background: #00ff0020; color: #00ff00; border: 1px solid #00ff0040; }
.level-2 { background: #ffaa0020; color: #ffaa00; border: 1px solid #ffaa0040; }
.level-3 { background: #ff444420; color: #ff4444; border: 1px solid #ff444440; }
.vector { display: inline-block; padding: 2px 10px; border-radius: 10px;
          font-size: 0.7rem; margin-left: 6px; }
.vec-WEB     { background: #5b8dee20; color: #5b8dee; border: 1px solid #5b8dee40; }
.vec-NETWORK { background: #e8734a20; color: #e8734a; border: 1px solid #e8734a40; }
.vec-ANDROID { background: #52c98b20; color: #52c98b; border: 1px solid #52c98b40; }
.vulns { font-size: 0.75rem; color: #666; margin: 8px 0; }
.url { font-size: 0.75rem; color: #5b8dee; word-break: break-all; margin-top: 8px; }
.status { width: 8px; height: 8px; border-radius: 50%; display: inline-block; margin-right: 6px; }
.status-up   { background: #00ff00; box-shadow: 0 0 6px #00ff00; }
.status-down { background: #ff4444; }
.status-row { display: flex; align-items: center; font-size: 0.75rem;
              color: #555; margin-top: 10px; }
.info-box { background: #141414; border: 1px solid #222; border-radius: 8px;
            padding: 20px; margin-bottom: 30px; }
.info-row { display: flex; gap: 40px; flex-wrap: wrap; }
.info-item { display: flex; flex-direction: column; gap: 4px; }
.info-label { font-size: 0.65rem; color: #444; text-transform: uppercase;
              letter-spacing: 2px; }
.info-value { font-size: 1rem; color: #00ff00; font-weight: bold; }
.cmd-box { background: #0a0a0a; border: 1px solid #1a1a1a; border-radius: 6px;
           padding: 16px; margin-top: 8px; }
.cmd-box code { color: #00ff00; font-size: 0.8rem; display: block;
                margin: 4px 0; }
.cmd-label { color: #444; font-size: 0.65rem; letter-spacing: 2px;
             text-transform: uppercase; margin-bottom: 8px; }
</style></head><body>

<div class="header">
    <div>
        <h1>◈ SHADOW LAB</h1>
        <p>Vulnerable Practice Environment — by Mr Joker · Shadow Suite</p>
    </div>
    <div class="badge">⚠ ISOLATED ENVIRONMENT</div>
</div>

<div class="container">

    <div class="info-box">
        <div class="info-row">
            <div class="info-item">
                <span class="info-label">VM IP</span>
                <span class="info-value">{{ ip }}</span>
            </div>
            <div class="info-item">
                <span class="info-label">Máquinas</span>
                <span class="info-value">{{ machines|length }}</span>
            </div>
            <div class="info-item">
                <span class="info-label">Nível 1</span>
                <span class="info-value" style="color:#00ff00">{{ machines|selectattr('level','eq',1)|list|length }}</span>
            </div>
            <div class="info-item">
                <span class="info-label">Nível 2</span>
                <span class="info-value" style="color:#ffaa00">{{ machines|selectattr('level','eq',2)|list|length }}</span>
            </div>
            <div class="info-item">
                <span class="info-label">Nível 3</span>
                <span class="info-value" style="color:#ff4444">{{ machines|selectattr('level','eq',3)|list|length }}</span>
            </div>
        </div>

        <div class="cmd-box" style="margin-top:16px">
            <div class="cmd-label">Acesso via Termux / SSH</div>
            <code>ssh shadowlab@{{ ip }}</code>
            <code style="color:#666"># password: ShadowLab2024!</code>
            <code style="color:#666"># depois: python3 /opt/shadowlab/shadowlab.py targets</code>
        </div>
    </div>

    <div class="section-title">// alvos disponíveis</div>
    <div class="grid">
    {% for m in machines %}
        <div class="card">
            <div class="card-header">
                <div>
                    <div class="card-title">{{ m.name }}</div>
                    <div class="card-id">{{ m.id }}</div>
                </div>
            </div>
            <span class="level level-{{ m.level }}">
                {% if m.level == 1 %}🟢 INICIANTE
                {% elif m.level == 2 %}🟡 INTERMÉDIO
                {% else %}🔴 AVANÇADO{% endif %}
            </span>
            <span class="vector vec-{{ m.vector }}">{{ m.vector }}</span>
            <div class="vulns">{{ m.vulns }}</div>
            <div class="url">{{ m.url.replace('{ip}', ip) }}</div>
            <div class="status-row">
                <span class="status {{ 'status-up' if m.up else 'status-down' }}"></span>
                {{ 'Online' if m.up else 'Offline' }}
            </div>
        </div>
    {% endfor %}
    </div>

</div></body></html>
"""

@app.route('/')
def index():
    ip = get_ip()
    machines = []
    for m in MACHINES:
        m2 = dict(m)
        m2['up'] = check_port(m2['port'])
        machines.append(m2)
    return render_template_string(TEMPLATE, machines=machines, ip=ip)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8079, debug=False)
DASHPY

cat > /etc/systemd/system/shadowlab-dashboard.service << 'SVCDASH'
[Unit]
Description=Shadow Lab Dashboard
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/shadowlab/dashboard/app.py
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
SVCDASH

systemctl daemon-reload >> "$LOG_FILE" 2>&1
systemctl enable shadowlab-dashboard >> "$LOG_FILE" 2>&1
systemctl start shadowlab-dashboard >> "$LOG_FILE" 2>&1
log_ok "Dashboard na porta 8079!"

# ════════════════════════════════════════════════════════════
# RESUMO FINAL
# ════════════════════════════════════════════════════════════
IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}${BOLD}  ╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}  ║       ✅  SHADOW LAB — INSTALAÇÃO CONCLUÍDA!        ║${RESET}"
echo -e "${GREEN}${BOLD}  ╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${CYAN}IP da VM      :${RESET} ${BOLD}$IP${RESET}"
echo ""
echo -e "  ${GREEN}🟢 NÍVEL 1 — INICIANTE${RESET}"
echo -e "  ${DIM}  DVWA           :${RESET} http://$IP:8010"
echo -e "  ${DIM}  FTP Vulnerável :${RESET} ftp://$IP:8021"
echo -e "  ${DIM}  SSH Fraco      :${RESET} ssh weakuser@$IP -p 8022"
echo ""
echo -e "  ${YELLOW}🟡 NÍVEL 2 — INTERMÉDIO${RESET}"
echo -e "  ${DIM}  Redis No Auth  :${RESET} redis-cli -h $IP -p 8379"
echo -e "  ${DIM}  Vulnerable API :${RESET} http://$IP:8050"
echo ""
echo -e "  ${RED}🔴 NÍVEL 3 — AVANÇADO${RESET}"
echo -e "  ${DIM}  LFI → RCE     :${RESET} http://$IP:8051"
echo ""
echo -e "  ${MAGENTA}◈  DASHBOARD    :${RESET} http://$IP:8079"
echo ""
echo -e "  ${CYAN}Acesso Termux / SSH:${RESET}"
echo -e "  ${GREEN}  ssh shadowlab@$IP${RESET}"
echo -e "  ${DIM}  password: ShadowLab2024!${RESET}"
echo ""
echo -e "  ${DIM}Log completo: $LOG_FILE${RESET}"
echo -e "  ${DIM}Shadow Suite — The Offensive Arsenal · github.com/mrjoker-web${RESET}"
echo ""
