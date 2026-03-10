# Contributing to WraithC2

First off — thank you for taking the time to contribute.
WraithC2 is an educational red-team research project and every improvement, bug report, and idea helps.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Before You Start](#before-you-start)
3. [Ways to Contribute](#ways-to-contribute)
4. [Development Environment Setup](#development-environment-setup)
5. [Project Structure](#project-structure)
6. [Good First Issues](#good-first-issues)
7. [Submitting a Bug Report](#submitting-a-bug-report)
8. [Submitting a Feature Request](#submitting-a-feature-request)
9. [Pull Request Process](#pull-request-process)
10. [Code Style Guidelines](#code-style-guidelines)
11. [Testing Checklist](#testing-checklist)
12. [Security Disclosure](#security-disclosure)

---

## Code of Conduct

By participating in this project you agree to:

- Use the tool **only on systems you own or have explicit written authorisation to test**
- Not post issues or PRs containing real target data, real credentials, or screenshots of live compromises
- Keep all discussion technical and professional

Contributions that appear to facilitate unauthorised access will be closed without review.

---

## Before You Start

- Check the [open issues](https://github.com/farooq9/wraithc2/issues) to make sure your bug or feature is not already tracked
- For large changes (new command category, new transport, new AI provider), open an issue first to discuss before writing code
- All development and testing must be done in an **isolated VM** — never test on your host machine or production systems

---

## Ways to Contribute

| Type | Description |
|------|-------------|
| Bug fix | Fix broken behaviour in `wraith.py` or `control.py` |
| New AI provider | Add a 5th provider (e.g. Mistral AI, Cohere, Together AI) |
| New built-in command | Add a new capability to the agent |
| Improve wizard | Better UX in `_run_setup_wizard()` in `control.py` |
| Documentation | Fix typos, improve clarity, add examples |
| Translate README | Translate to another language |
| Test & report | Test on a specific Windows version and report results |

---

## Development Environment Setup

```powershell
# 1. Fork the repo on GitHub, then clone your fork
git clone https://github.com/farooq9/wraithc2
cd wraithc2

# 2. Create a virtual environment
python -m venv .venv
.venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. pywin32 post-install (Windows only, run once)
python .venv\Scripts\pywin32_postinstall.py -install

# 5. Copy config template
# Edit config.py and fill in your own API keys and Gist ID
# NEVER commit real API keys — the file uses placeholders by default

# 6. Run the operator CLI
python control.py
```

**Required:** Windows 10 or Windows 11 VM for testing `wraith.py`.
`control.py` can be developed and tested on any OS.

---

## Project Structure

```
wraithc2/
  wraith.py          Agent / implant — runs on the target Windows machine
  control.py         Operator CLI — runs on the attacker machine
  config.py          Shared configuration (API keys, Gist ID, etc.)
  compile.bat        Compiles wraith.py to dist\wraith.exe via PyInstaller
  requirements.txt   Python dependencies
  CONTRIBUTING.md    This file
  README.md          Project overview and quick start
```

### Key classes and functions

| File | Symbol | Purpose |
|------|--------|---------|
| `wraith.py` | `WraithAgent` | Main agent class |
| `wraith.py` | `WraithAgent.run()` | Main polling loop |
| `wraith.py` | `WraithAgent._call_ai()` | Sends prompt to LLM, returns action JSON |
| `wraith.py` | `WraithAgent.execute_command()` | Dispatches action to correct method |
| `wraith.py` | `WraithAgent._send_result()` | Posts result back to Gist |
| `wraith.py` | `WraithAgent.exec_code()` | Runs AI-generated code (PS/Python/VBS/Batch) |
| `control.py` | `_run_setup_wizard()` | Interactive config generator |
| `control.py` | main loop | Reads operator input, writes to Gist |

---

## Good First Issues

These are well-scoped tasks ideal for a first contribution:

### 1. Add Mistral AI as a 5th provider

`config.py` — add:
```python
MISTRAL_API_KEY = 'YOUR_MISTRAL_KEY_HERE'   # la-...
MISTRAL_MODEL   = 'mistral-large-latest'
```

`wraith.py` — in `_call_ai()`, add a branch for `AI_PROVIDER == 'mistral'`:
```python
# Mistral uses OpenAI-compatible /v1/chat/completions
# Base URL: https://api.mistral.ai/v1/chat/completions
```

`control.py` — add to `_PROVIDER_MODELS['mistral']` and `_KEY_HINTS`.

---

### 2. Add model name to the agent's result output

Currently results don't show which AI model interpreted the command.
Change `_send_result()` to append the model name:
```
[screenshot] saved to ... | interpreted by: meta/llama-3.3-70b-instruct
```

---

### 3. Add a `sysinfo` built-in command (pre-AI bypass)

In `control.py` / `wraith.py` pre-AI bypass table, add:
```python
r'sys\s*info|system\s*info|system\s*information': 'sysinfo'
```

In `execute_command()`:
```python
elif action == 'sysinfo':
    return self.get_sysinfo()
```

`get_sysinfo()` should return: hostname, OS version, CPU, RAM, current user, SID, domain.

---

### 4. Improve setup wizard validation

Currently the wizard accepts any string for the API key.
Add basic format validation:
```python
# NVIDIA keys start with nvapi-
# OpenRouter keys start with sk-or-v1-
# Anthropic keys start with sk-ant-
# Groq keys start with gsk_
# GitHub PATs start with ghp_ or github_pat_
```

Warn the user (don't block) if the key doesn't match the expected prefix.

---

### 5. Add `--verbose` flag to control.py

Currently no way to see raw Gist JSON. Add:
```
OP> verbose on
OP> verbose off
```
When on, print the raw JSON written to and read from the Gist.

---

## Submitting a Bug Report

Open an issue at: https://github.com/farooq9/wraithc2/issues/new

Include:
- **Windows version** (e.g. Windows 11 23H2)
- **Python version** (`python --version`)
- **AI provider and model** from your `config.py`
- **What you did** — exact steps to reproduce
- **What you expected** to happen
- **What actually happened** — paste the error message or describe the behaviour
- **Relevant log output** (redact any API keys before pasting)

Do **not** include:
- Real API keys
- Real GitHub tokens
- Screenshots of live targets
- Any data from systems you don't own

---

## Submitting a Feature Request

Open an issue with the label `enhancement`.

Describe:
1. **The problem** — what can't you do today?
2. **Your proposed solution** — how would it work?
3. **Alternatives considered** — did you think of other approaches?
4. **Willingness to implement** — are you offering to write the code?

---

## Pull Request Process

1. **Fork** the repository
2. **Create a branch** with a descriptive name:
   ```bash
   git checkout -b feature/add-mistral-provider
   git checkout -b fix/keylogger-crash-on-win10
   ```
3. **Make your changes** — keep commits focused (one logical change per commit)
4. **Test** using the checklist below
5. **Update README.md** if you added a new feature or changed behaviour
6. **Push** to your fork and open a Pull Request against `main`

### PR description template

```
## What this PR does
[One sentence summary]

## Why
[Problem being solved or motivation]

## How it was tested
- Windows version: 
- Python version:
- AI provider tested with:
- Steps taken:

## Checklist
- [ ] Tested in isolated VM
- [ ] No real API keys in code
- [ ] README updated if needed
- [ ] Existing features still work
```

---

## Code Style Guidelines

- **Python 3.11+** — use f-strings, not `.format()` or `%`
- **No external dependencies** beyond what's already in `requirements.txt` — discuss first before adding
- **Error handling:** wrap hardware calls (webcam, audio, keylogger) in try/except — the agent must not crash on missing hardware
- **Logging:** use `logger.error()` / `logger.info()` from the module-level `logging.getLogger()` — never `print()` inside `wraith.py` (no console)
- **Secrets:** never hardcode, never log API keys or tokens
- **Line length:** 120 characters max
- **Comments:** only where logic is non-obvious — don't comment obvious code

---

## Testing Checklist

Before submitting a PR, verify these manually in a Windows VM:

```
[ ] python control.py starts without errors
[ ] 'setup' command completes and writes config.py
[ ] wraith.py starts and polls Gist without errors
[ ] A basic command goes end-to-end (e.g. "list processes")
[ ] Screenshot command works
[ ] compile.bat produces dist\wraith.exe
[ ] wraith.exe runs without console window
```

---

## Security Disclosure

If you discover a security vulnerability in WraithC2 **itself** (not a feature — an actual unintended vulnerability in the operator tooling or config handling), please do not open a public issue.

Contact: open a **private security advisory** via GitHub:
Repository → Security → Advisories → Report a vulnerability

Include a description and proof of concept.
