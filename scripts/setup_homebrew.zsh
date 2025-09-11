#!/bin/zsh
set -euo pipefail

# 1) Sudo once (so later steps don't interrupt)
if ! sudo -v &>/dev/null; then
  echo "🔐 This script needs sudo privileges."
  exit 1
fi

# 2) Xcode Command Line Tools (if missing)
if ! xcode-select -p &>/dev/null; then
  echo "🔧 Installing Xcode Command Line Tools…"
  xcode-select --install || true
  read "REPLY?⏸️ Press [Enter] after the tools finish installing…"
else
  echo "✅ Xcode Command Line Tools already installed"
fi

# 3) Homebrew (install if missing) + shellenv
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew…"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH in this shell
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
echo "✅ Homebrew ready"

# 4) Brewfile path
DOTFILES="$HOME/.dotfiles"
BREWFILE="$DOTFILES/homebrew/Brewfile"
if [[ ! -f "$BREWFILE" ]]; then
  echo "❌ Brewfile not found at: $BREWFILE"
  exit 1
fi

# 5) Simple MAS preflight: give you time to sign in (no detection)
if grep -qE '(^| )mas ' "$BREWFILE"; then
  # Make sure mas exists so Brewfile can use it
  if ! command -v mas >/dev/null 2>&1; then
    echo "📦 Installing mas (Mac App Store CLI)…"
    brew install mas
  fi
  echo "🛍️ Please sign into the App Store (App Store → Account)."
  echo "   I’ll open it; sign in, then return here."
  open -a "App Store" || true
  read "REPLY?⏸️ Press [Enter] to continue once you're signed in…"
fi

# 6) Install everything from the Brewfile
echo "📦 Installing from Brewfile…"
brew bundle --file="$BREWFILE"
echo "✅ Brewfile install complete"

# --- Postflight: ensure 1Password is launched once so Gatekeeper prompts
if [[ -d "/Applications/1Password.app" ]]; then
  echo "🔓 Opening 1Password once to clear Gatekeeper prompt…"
  open -ga "/Applications/1Password.app" || true
  echo "⏸️ When 1Password opens, approve the 'downloaded from Internet' prompt, then quit it and return here."
  read -r "?Press [Enter] to continue…"
fi

# 8) Brew maintenance
echo "🔄 brew update && brew upgrade && brew cleanup…"
brew update
brew upgrade
brew cleanup
echo "✅ Homebrew maintenance complete"

# 9) VS Code CLI + extensions (best-effort, no pauses)
VSCODE_EXTS="$DOTFILES/ide/vscode/extensions.txt"
if command -v code >/dev/null 2>&1 && [[ -f "$VSCODE_EXTS" ]]; then
  echo "🧩 Installing VS Code extensions…"
  while IFS= read -r ext; do
    [[ -n "$ext" ]] && code --install-extension "$ext" --force || true
  done < "$VSCODE_EXTS"
  echo "✅ VS Code extensions installed"
else
  echo "ℹ️ Skip VS Code extensions (CLI not found or list missing)."
fi

echo "🎉 Homebrew setup finished."