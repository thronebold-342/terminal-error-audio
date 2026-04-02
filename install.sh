#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  terminal-error-audio — Universal Installer
#  Supports: Oh My Zsh · Zinit · Antigen · plain zsh · bash
#
#  One-liner install:
#    curl -fsSL https://raw.githubusercontent.com/thronebold-342/terminal-error-audio/main/install.sh | bash
# ──────────────────────────────────────────────────────────────────────────────

set -e

PLUGIN_NAME="terminal-error-audio"
REPO_URL="https://raw.githubusercontent.com/thronebold-342/${PLUGIN_NAME}/main"
PLUGIN_FILE="${PLUGIN_NAME}.plugin.zsh"

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}ℹ${RESET}  $*"; }
success() { echo -e "${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "${RED}✖${RESET}  $*" >&2; exit 1; }

echo -e "\n${BOLD}  terminal-error-audio — installer${RESET}"
echo    "  ─────────────────────────────────"

# ── Detect OS ─────────────────────────────────────────────────────────────────
OS="$(uname -s)"
[[ "$OS" != "Darwin" && "$OS" != "Linux" ]] && \
  error "Unsupported OS: $OS"

# ── Detect shell ──────────────────────────────────────────────────────────────
SHELL_NAME="$(basename "$SHELL")"
info "Detected shell : ${BOLD}$SHELL_NAME${RESET}"

if   [[ "$SHELL_NAME" == "zsh" ]];  then RC="$HOME/.zshrc"
elif [[ "$SHELL_NAME" == "bash" ]]; then RC="$HOME/.bash_profile"
else error "Unsupported shell: $SHELL_NAME  (zsh or bash required)"
fi

info "Config file    : ${BOLD}$RC${RESET}"

# ── Check: already installed ──────────────────────────────────────────────────
if grep -q "_TEA_LOADED\|terminal-error-audio" "$RC" 2>/dev/null; then
  warn "Already installed. To reinstall: run uninstall.sh first, then re-run."
  exit 0
fi

# ── Detect plugin manager ─────────────────────────────────────────────────────
HAS_OMZ=false
HAS_ZINIT=false
HAS_ANTIGEN=false

[[ -d "$HOME/.oh-my-zsh" ]] && HAS_OMZ=true
grep -q "zinit\|zplugin" "$RC" 2>/dev/null && HAS_ZINIT=true
grep -q "antigen" "$RC" 2>/dev/null && HAS_ANTIGEN=true

# ── Helper: download the plugin file ─────────────────────────────────────────
download_plugin() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  if command -v curl &>/dev/null; then
    curl -fsSL "${REPO_URL}/${PLUGIN_FILE}" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -qO "$dest" "${REPO_URL}/${PLUGIN_FILE}"
  else
    error "Neither curl nor wget found. Please install one and retry."
  fi
}

# ── Linux dependency hints ────────────────────────────────────────────────────
if [[ "$OS" == "Linux" ]]; then
  echo ""
  info "Linux detected. For audio to work you may need to install:"
  echo "     Sound:  sudo apt install pulseaudio-utils   # paplay"
  echo "     Speech: sudo apt install espeak-ng           # espeak-ng"
  echo ""
fi

# ══════════════════════════════════════════════════════════════════════════════
# Installation paths (priority order)
# ══════════════════════════════════════════════════════════════════════════════

# ── Path 1: Oh My Zsh ─────────────────────────────────────────────────────────
if [[ "$HAS_OMZ" == "true" ]]; then
  info "Oh My Zsh detected — installing as a custom plugin"
  PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/${PLUGIN_NAME}"
  download_plugin "${PLUGIN_DIR}/${PLUGIN_FILE}"
  success "Plugin saved to ${PLUGIN_DIR}"

  # Add to plugins=(...) if not already present
  if grep -q "plugins=(" "$RC"; then
    if ! grep -q "$PLUGIN_NAME" "$RC"; then
      # Insert the plugin name into the plugins array
      sed -i.bak "s/plugins=(\(.*\))/plugins=(\1 ${PLUGIN_NAME})/" "$RC"
      success "Added '${PLUGIN_NAME}' to plugins=() in $RC"
    else
      warn "'${PLUGIN_NAME}' already in plugins=(). Skipping."
    fi
  else
    echo "" >> "$RC"
    echo "plugins=($PLUGIN_NAME)" >> "$RC"
    success "Created plugins=($PLUGIN_NAME) in $RC"
  fi

# ── Path 2: Zinit ─────────────────────────────────────────────────────────────
elif [[ "$HAS_ZINIT" == "true" ]]; then
  info "Zinit detected — adding zinit snippet"
  cat >> "$RC" << EOF

# terminal-error-audio
zinit light thronebold-342/${PLUGIN_NAME}
EOF
  success "Added zinit snippet to $RC"

# ── Path 3: Antigen ───────────────────────────────────────────────────────────
elif [[ "$HAS_ANTIGEN" == "true" ]]; then
  info "Antigen detected — adding antigen bundle"
  # Insert before 'antigen apply'
  sed -i.bak "/antigen apply/i antigen bundle thronebold-342/${PLUGIN_NAME}" "$RC"
  success "Added antigen bundle line to $RC"

# ── Path 4: Standalone (source line) ─────────────────────────────────────────
else
  info "No plugin manager found — using standalone source"
  PLUGIN_DIR="$HOME/.config/${PLUGIN_NAME}"
  download_plugin "${PLUGIN_DIR}/${PLUGIN_FILE}"
  success "Plugin saved to ${PLUGIN_DIR}"

  cat >> "$RC" << EOF

# terminal-error-audio — https://github.com/thronebold-342/${PLUGIN_NAME}
source "\$HOME/.config/${PLUGIN_NAME}/${PLUGIN_FILE}"
EOF
  success "Added source line to $RC"
fi

# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}  Installation complete!${RESET}"
echo    "  ────────────────────────────────────────────────────────"
echo    "  Open a NEW terminal tab (or run: source $RC)"
echo    "  to activate the plugin."
echo    ""
echo    "  Test it:   python3 -c \"raise ValueError('broken')\"  "
echo    "             ls /path/that/does/not/exist              "
echo    ""
echo    "  Customise in ~/.zshrc (before the plugin loads):     "
echo    "    export TERM_ERROR_SOUND=\"/System/Library/Sounds/Basso.aiff\""
echo    "    export TERM_ERROR_VOICE=\"Samantha\"   # macOS only  "
echo    "    export TERM_ERROR_SPEAK=\"false\"       # sound only  "
echo    ""
echo    "  Uninstall: bash uninstall.sh"
echo    "  ────────────────────────────────────────────────────────"
echo    ""
