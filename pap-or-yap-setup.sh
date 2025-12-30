#!/usr/bin/env bash
# pap-or-yap-setup.sh
# Lightweight cross-platform project setup script for the Pap-or-yap repo.
# - Creates a Python venv and installs requirements if present
# - Runs npm install if package.json exists
# - Copies .env.example -> .env if present
# - Prints guidance for missing tools

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

info()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*"; }

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

detect_os() {
  unameOut="$(uname -s)"
  case "${unameOut}" in
    Linux*)   os=linux;;
    Darwin*)  os=macos;;
    *)        os=other;;
  esac
  printf "%s" "$os"
}

ensure_tool() {
  local tool=$1
  if ! command_exists "$tool"; then
    warn "Required tool '$tool' is not installed."
    return 1
  fi
  return 0
}

try_install_tool() {
  local tool=$1
  local os="$2"
  if [ "$os" = "linux" ]; then
    if command_exists apt-get; then
      sudo apt-get update && sudo apt-get install -y "$tool" || return 1
    elif command_exists dnf; then
      sudo dnf install -y "$tool" || return 1
    else
      return 1
    fi
  elif [ "$os" = "macos" ]; then
    if command_exists brew; then
      brew install "$tool" || return 1
    else
      return 1
    fi
  else
    return 1
  fi
}

main() {
  info "Running pap-or-yap setup..."
  os="$(detect_os)"
  info "Detected OS: $os"

  # Check basic tools
  missing=()
  for t in git curl; do
    if ! ensure_tool "$t"; then
      missing+=("$t")
    fi
  done

  if [ "${#missing[@]}" -ne 0 ]; then
    warn "Missing tools: ${missing[*]}"
    for t in "${missing[@]}"; do
      if try_install_tool "$t" "$os"; then
        ok "Installed $t"
      else
        warn "Could not install $t automatically. Please install it manually."
      fi
    done
  fi

  # Python setup
  if command_exists python3; then
    PY=python3
  elif command_exists python; then
    PY=python
  else
    warn "Python is not installed. Skipping Python virtualenv setup."
    PY=""
  fi

  if [ -n "$PY" ]; then
    info "Creating virtual environment at .venv using $PY"
    "$PY" -m venv .venv
    # shellcheck disable=SC1090
    . .venv/bin/activate
    ok "Activated .venv"

    if [ -f requirements.txt ]; then
      info "Installing Python requirements from requirements.txt"
      pip install --upgrade pip
      pip install -r requirements.txt
      ok "Python dependencies installed"
    else
      info "No requirements.txt found; skipping pip install"
    fi
  fi

  # Node setup
  if [ -f package.json ]; then
    if ensure_tool npm; then
      info "Installing Node dependencies (npm ci)"
      npm ci
      ok "Node dependencies installed"
    else
      warn "npm not found; please install Node.js / npm to install Node dependencies"
    fi
  fi

  # env file
  if [ -f .env.example ] && [ ! -f .env ]; then
    info "Copying .env.example -> .env"
    cp .env.example .env
    ok "Created .env from example. Edit it with project-specific values."
  fi

  # Make executable helper scripts
  if [ -d scripts ]; then
    info "Making scripts/* executable"
    chmod +x scripts/* || true
  fi

  info "Setup complete."
  printf "\nNext steps:\n"
  if [ -f .venv/bin/activate ]; then
    printf "  - Activate Python virtualenv:  source .venv/bin/activate\n"
  fi
  if [ -f package.json ]; then
    printf "  - Run npm scripts:               npm run <script>\n"
  fi
  printf "  - Run tests/build:               make test | make build\n\n"
  ok "pap-or-yap setup finished"
}

main "$@"