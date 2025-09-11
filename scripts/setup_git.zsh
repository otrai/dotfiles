#!/bin/zsh
set -euo pipefail

echo "🔎 Validating Git configuration…"

# ~/.gitconfig should be a symlink created by Dotbot
if [ -L "$HOME/.gitconfig" ]; then
  echo "✅ ~/.gitconfig is a symlink (as expected)."
else
  echo "❌ ~/.gitconfig is not a symlink (Dotbot should create it)."
  exit 1
fi

# Identity must be present
if git config --get user.name >/dev/null; then
  echo "✅ user.name set: $(git config --get user.name)"
else
  echo "⚠️ user.name not set"
fi

if git config --get user.email >/dev/null; then
  echo "✅ user.email set: $(git config --get user.email)"
else
  echo "⚠️ user.email not set"
fi

# Global ignore should be the OS-neutral path
expected="$HOME/.config/git/ignore"
current="$(git config --get core.excludesfile 2>/dev/null || true)"

# Normalize ~ to $HOME for comparison
exp_resolved="${expected/#\~/$HOME}"
cur_resolved="${current/#\~/$HOME}"

if [[ -n "$cur_resolved" && "$cur_resolved" == "$exp_resolved" ]]; then
  echo "✅ core.excludesfile -> $current"
else
  echo "⚠️ core.excludesfile is '${current:-<unset>}' (expected '$expected')"
fi

echo "✅ Git validation complete."