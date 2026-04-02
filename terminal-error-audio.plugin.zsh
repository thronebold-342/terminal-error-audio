# ──────────────────────────────────────────────────────────────────────────────
#  terminal-error-audio.plugin.zsh
#  Plays a sound + speaks the error whenever any terminal command fails.
#  Compatible: Oh My Zsh · Zinit · Antigen · bash · standalone source
# ──────────────────────────────────────────────────────────────────────────────

# Guard: prevent double-loading
[[ -n "$_TEA_LOADED" ]] && return 0
export _TEA_LOADED=1

# ── User-configurable options (set these BEFORE sourcing / in your .zshrc) ────
#
#   TERM_ERROR_SOUND   Path to a .aiff file       (macOS default: Funk.aiff)
#   TERM_ERROR_SPEAK   "true" / "false"           (default: true)
#   TERM_ERROR_VOICE   macOS voice name           (default: system voice)
#
# Example overrides in .zshrc:
#   export TERM_ERROR_SOUND="/System/Library/Sounds/Basso.aiff"
#   export TERM_ERROR_VOICE="Samantha"
#   export TERM_ERROR_SPEAK="false"

: "${TERM_ERROR_SPEAK:=true}"
: "${TERM_ERROR_SOUND:=/System/Library/Sounds/Funk.aiff}"

_tea_has() { command -v "$1" &>/dev/null; }

# ── Play an error sound ───────────────────────────────────────────────────────
_tea_play_sound() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    _tea_has afplay && afplay "$TERM_ERROR_SOUND" &>/dev/null &
  else
    if _tea_has paplay; then
      paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga &>/dev/null &
    elif _tea_has aplay; then
      aplay -q /usr/share/sounds/freedesktop/stereo/dialog-error.oga &>/dev/null &
    fi
  fi
}

# ── Speak a message ───────────────────────────────────────────────────────────
_tea_speak() {
  [[ "$TERM_ERROR_SPEAK" != "true" ]] && return 0
  [[ -z "$1" ]] && return 0
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if [[ -n "$TERM_ERROR_VOICE" ]]; then
      _tea_has say && say -v "$TERM_ERROR_VOICE" "$1" &>/dev/null &
    else
      _tea_has say && say "$1" &>/dev/null &
    fi
  else
    if _tea_has espeak-ng; then
      espeak-ng "$1" &>/dev/null &
    elif _tea_has espeak; then
      espeak "$1" &>/dev/null &
    fi
  fi
}

# ── Track the last command typed ──────────────────────────────────────────────
_tea_last_cmd=""
_tea_preexec() {
  _tea_last_cmd="$1"
}

# ── After every command: check exit code ─────────────────────────────────────
_tea_precmd() {
  local _exit=$?
  [[ $_exit -eq 0 ]] && return 0

  # Play the sound immediately
  _tea_play_sound

  # Build a message from the command that failed
  local _cmd_name="${_tea_last_cmd%% *}"
  local _msg=""

  case "$_cmd_name" in
    python|python3)  _msg="Python error." ;;
    node|npm|npx)    _msg="Node error." ;;
    git)             _msg="Git error." ;;
    cd)              _msg="No such directory." ;;
    brew)            _msg="Brew error." ;;
    *)               _msg="Error in $_cmd_name." ;;
  esac

  [[ $_exit -ne 127 ]] && _msg="$_msg Exit code $_exit."
  [[ $_exit -eq 127 ]] && _msg="Command not found: $_cmd_name."

  _tea_speak "$_msg"
}

# ── Register hooks ────────────────────────────────────────────────────────────
if [[ -n "$ZSH_VERSION" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _tea_preexec
  add-zsh-hook precmd  _tea_precmd
elif [[ -n "$BASH_VERSION" ]]; then
  trap '_tea_preexec "$BASH_COMMAND"' DEBUG
  if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="_tea_precmd"
  else
    PROMPT_COMMAND="${PROMPT_COMMAND%;}; _tea_precmd"
  fi
fi
