#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  terminal-error-audio — Uninstaller
# ──────────────────────────────────────────────────────────────────────────────

PLUGIN_NAME="terminal-error-audio"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}ℹ${RESET}  $*"; }
success() { echo -e "${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }

SHELL_NAME="$(basename "$SHELL")"
[[ "$SHELL_NAME" == "zsh" ]]  && RC="$HOME/.zshrc"
[[ "$SHELL_NAME" == "bash" ]] && RC="$HOME/.bash_profile"

echo -e "\n${BOLD}  terminal-error-audio — uninstaller${RESET}\n"

# ── Remove OMZ custom plugin dir ──────────────────────────────────────────────
OMZ_PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/${PLUGIN_NAME}"
if [[ -d "$OMZ_PLUGIN_DIR" ]]; then
  rm -rf "$OMZ_PLUGIN_DIR"
  success "Removed OMZ plugin directory: $OMZ_PLUGIN_DIR"
fi

# ── Remove standalone config dir ──────────────────────────────────────────────
SA_DIR="$HOME/.config/${PLUGIN_NAME}"
if [[ -d "$SA_DIR" ]]; then
  rm -rf "$SA_DIR"
  success "Removed config directory: $SA_DIR"
fi

# ── Clean up RC file ──────────────────────────────────────────────────────────
if [[ -f "$RC" ]]; then
  cp "$RC" "${RC}.tea_backup"
  info "Backup saved: ${RC}.tea_backup"

  # Remove standalone source line and zinit/antigen lines
  sed -i.teatmp \
    "/${PLUGIN_NAME}/d;
     /_TEA_LOADED/d;
     /terminal-error-audio/d" "$RC"
  rm -f "${RC}.teatmp"

  # Remove the plugin from plugins=(... terminal-error-audio ...)
  sed -i.teatmp2 \
    "s/ ${PLUGIN_NAME}//g; s/${PLUGIN_NAME} //g" "$RC"
  rm -f "${RC}.teatmp2"

  success "Cleaned $RC"
fi

# ── Remove temp files ─────────────────────────────────────────────────────────
rm -f /tmp/tea_* 2>/dev/null && success "Removed temp files"

echo ""
echo -e "${GREEN}${BOLD}  Uninstalled successfully.${RESET}"
echo    "  Open a new terminal tab for changes to take effect."
echo    ""
