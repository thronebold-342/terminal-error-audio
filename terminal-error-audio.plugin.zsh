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
#   TERM_ERROR_SOUND   Path to a .aiff/.wav file  (macOS default: Funk.aiff)
#   TERM_ERROR_SPEAK   "true" / "false"           (default: true)
#   TERM_ERROR_VOICE   macOS voice name            (default: system voice)
#
# Example overrides in .zshrc:
#   export TERM_ERROR_SOUND="/System/Library/Sounds/Basso.aiff"
#   export TERM_ERROR_VOICE="Samantha"
#   export TERM_ERROR_SPEAK="false"

: "${TERM_ERROR_SPEAK:=true}"

# ── OS / tool detection ───────────────────────────────────────────────────────
_tea_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

_tea_has() { command -v "$1" &>/dev/null; }

# ── Play an error sound ───────────────────────────────────────────────────────
_tea_play_sound() {
  case "$(_tea_os)" in
    macos)
      local sound="${TERM_ERROR_SOUND:-/System/Library/Sounds/Funk.aiff}"
      _tea_has afplay && afplay "$sound" &>/dev/null &
      ;;
    linux)
      if _tea_has paplay; then
        paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga &>/dev/null &
      elif _tea_has aplay; then
        aplay -q /usr/share/sounds/freedesktop/stereo/dialog-error.oga &>/dev/null &
      elif _tea_has sox; then
        play -q -n synth 0.15 sine 880 vol 0.7 &>/dev/null &
      fi
      ;;
  esac
}

# ── Speak the error text ──────────────────────────────────────────────────────
_tea_speak() {
  [[ "$TERM_ERROR_SPEAK" != "true" ]] && return 0
  local text="$1"
  [[ -z "$text" ]] && return 0
  case "$(_tea_os)" in
    macos)
      if [[ -n "$TERM_ERROR_VOICE" ]]; then
        _tea_has say && say -v "$TERM_ERROR_VOICE" "$text" &>/dev/null &
      else
        _tea_has say && say "$text" &>/dev/null &
      fi
      ;;
    linux)
      if _tea_has espeak-ng; then
        espeak-ng "$text" &>/dev/null &
      elif _tea_has espeak; then
        espeak "$text" &>/dev/null &
      elif _tea_has festival; then
        echo "$text" | festival --tts &>/dev/null &
      fi
      ;;
  esac
}

# ── Stderr capture setup ──────────────────────────────────────────────────────
export _TEA_ERR_FILE
_TEA_ERR_FILE="$(mktemp /tmp/tea_XXXXXX 2>/dev/null || mktemp)"

# Redirect stderr through tee: still prints to terminal AND writes to file
exec 2> >(tee -a "$_TEA_ERR_FILE" >&2)

# ── Shell hooks ───────────────────────────────────────────────────────────────

# Before each command: wipe the capture file
_tea_preexec() {
  > "$_TEA_ERR_FILE" 2>/dev/null
}

# After each command: if it failed, make noise + speak
_tea_precmd() {
  local _exit=$?

  # Success — clear and return silently
  if [[ $_exit -eq 0 ]]; then
    > "$_TEA_ERR_FILE" 2>/dev/null
    return 0
  fi

  # ── Failed ── play sound immediately
  _tea_play_sound

  # Give the tee process a moment to flush into the file
  sleep 0.15

  # ── Build a speakable message from captured stderr ────────────────
  local _msg=""
  if [[ -s "$_TEA_ERR_FILE" ]]; then
    _msg=$(
      grep -v '^[[:space:]]*$' "$_TEA_ERR_FILE" \
        | tail -4 \
        | sed $'s/\x1b\\[[0-9;]*[mK]//g' \
        | tr -d $'\r' \
        | tr '\n' ' ' \
        | sed 's/  */ /g; s/^ //; s/ $//' \
        | cut -c1-240
    )
  fi

  # Speak the captured message, or a generic fallback
  if [[ -n "$_msg" ]]; then
    _tea_speak "$_msg"
  else
    _tea_speak "Error. Exit code $_exit."
  fi

  > "$_TEA_ERR_FILE" 2>/dev/null
}

# ── Register hooks ────────────────────────────────────────────────────────────
if [[ -n "$ZSH_VERSION" ]]; then
  # Zsh: use the proper hook API
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _tea_preexec
  add-zsh-hook precmd  _tea_precmd

elif [[ -n "$BASH_VERSION" ]]; then
  # Bash: DEBUG trap fires before each command; PROMPT_COMMAND fires after
  trap '_tea_preexec' DEBUG
  if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="_tea_precmd"
  else
    PROMPT_COMMAND="${PROMPT_COMMAND%;}; _tea_precmd"
  fi
fi

# ── Cleanup temp file when the shell exits ────────────────────────────────────
trap 'rm -f "$_TEA_ERR_FILE" 2>/dev/null' EXIT
