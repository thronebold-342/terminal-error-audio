# terminal-error-audio 🔊

> Plays a sound and **speaks the error message** whenever any terminal command fails — bash errors, Python exceptions, command not found, all of it.

Works on **macOS** and **Linux**. Compatible with **Oh My Zsh**, **Zinit**, **Antigen**, plain **zsh**, and **bash**.

---

## Install

### One-liner (works for everyone)

```bash
curl -fsSL https://raw.githubusercontent.com/thronebold-342/terminal-error-audio/main/install.sh | bash
```

Then open a **new terminal tab**. Done.

---

### Oh My Zsh

```bash
git clone https://github.com/thronebold-342/terminal-error-audio \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/terminal-error-audio
```

Add to your `~/.zshrc`:

```zsh
plugins=(... terminal-error-audio)
```

---

### Zinit

```zsh
zinit light thronebold-342/terminal-error-audio
```

---

### Antigen

```zsh
antigen bundle thronebold-342/terminal-error-audio
```

---

### Manual / standalone

```bash
mkdir -p ~/.config/terminal-error-audio
curl -fsSL https://raw.githubusercontent.com/thronebold-342/terminal-error-audio/main/terminal-error-audio.plugin.zsh \
  -o ~/.config/terminal-error-audio/terminal-error-audio.plugin.zsh

echo 'source "$HOME/.config/terminal-error-audio/terminal-error-audio.plugin.zsh"' >> ~/.zshrc
```

---

## What it does

| Event | What happens |
|---|---|
| Any command fails (exit ≠ 0) | Plays an error sound |
| stderr output exists | Speaks the last few lines out loud |
| No stderr (just a bad exit) | Says *"Error. Exit code N."* |

Tested with: Python tracebacks, `command not found`, `permission denied`, `ls` on missing paths, failing shell scripts, and more.

---

## Customise

Set these in your `~/.zshrc` **before** the plugin loads:

```zsh
# Change the sound (macOS — any file in /System/Library/Sounds/)
export TERM_ERROR_SOUND="/System/Library/Sounds/Basso.aiff"

# Change the macOS voice
export TERM_ERROR_VOICE="Samantha"

# Disable speech (sound only)
export TERM_ERROR_SPEAK="false"
```

### Available macOS sounds

`Basso` · `Blow` · `Bottle` · `Frog` · `Funk` *(default)* · `Glass` · `Hero` · `Morse` · `Ping` · `Pop` · `Purr` · `Sosumi` · `Submarine` · `Tink`

### Available macOS voices

Run `say -v ?` in your terminal to list all installed voices.

---

## Linux requirements

Audio and speech tools are not pre-installed on all distros. Install what you need:

```bash
# Debian / Ubuntu
sudo apt install pulseaudio-utils espeak-ng

# Arch
sudo pacman -S espeak-ng

# Fedora
sudo dnf install espeak-ng
```

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/thronebold-342/terminal-error-audio/main/uninstall.sh | bash
```

---

## How it works

1. On startup, `stderr` is redirected through `tee` — so it still prints to your terminal **and** is written to a temp file.
2. A `preexec` hook clears the temp file before every command.
3. A `precmd` hook checks the exit code after every command. On failure it plays a sound and passes the captured stderr text to `say` / `espeak`.

---

## Files

```
terminal-error-audio/
├── terminal-error-audio.plugin.zsh   ← the plugin (source this directly)
├── install.sh                         ← one-liner installer
├── uninstall.sh                       ← clean removal
└── README.md
```

---

## License

MIT
