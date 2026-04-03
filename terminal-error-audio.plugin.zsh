# ──────────────────────────────────────────────────────────────────────────────
#  terminal-error-audio.plugin.zsh (silent-only)
#  Plays a sound whenever any terminal command fails.
#  Compatible: Oh My Zsh · Zinit · Antigen · bash · standalone source
# ──────────────────────────────────────────────────────────────────────────────

# Guard: prevent double-loading
[[ -n "$_TEA_LOADED" ]] && return 0
export _TEA_LOADED=1

# ── User-configurable options (set BEFORE sourcing in your .zshrc) ────────────
: "${TERM_ERROR_SOUND:=/System/Library/Sounds/Funk.aiff}"

_tea_has() { command -v "$1" &>/dev/null; }

# ── Play an error sound ───────────────────────────────────────────────────────
_tea_play_sound() {
  if [[ "$(uname -s)" == "Darwin" ]]; then

    _tea_has afplay && ( afplay "$TERM_ERROR_SOUND" > /dev/null 2>&1 ) & disown
   # _tea_has afplay && afplay "$TERM_ERROR_SOUND" >/dev/null 2>&1 &
   
  else
    if _tea_has paplay; then
      paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga >/dev/null 2>&1 &
    elif _tea_has aplay; then
      aplay -q /usr/share/sounds/freedesktop/stereo/dialog-error.oga >/dev/null 2>&1 &
    fi
  fi
}

# ── After every command: check exit code ─────────────────────────────────────
_tea_precmd() {
  local _exit=$?
  [[ $_exit -eq 0 ]] && return 0
  _tea_play_sound
}

# ── Register hooks ────────────────────────────────────────────────────────────
if [[ -n "$ZSH_VERSION" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _tea_precmd
elif [[ -n "$BASH_VERSION" ]]; then
  PROMPT_COMMAND="_tea_precmd"
fi
