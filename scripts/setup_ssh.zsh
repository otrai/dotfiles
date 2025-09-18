#!/usr/bin/env zsh
# 🔐 setup_ssh.zsh — interactive SSH setup wizard
# Default: prefer 1Password SSH Agent (via ~/.1password/agent.sock symlink)
# Fallback: macOS ssh-agent + local key (create if missing)
# Hardens perms (dir 700, files 600/644)
# Shows resolved ssh config (ssh -G) and verifies GitHub access
# NOTE: This script does NOT write your ~/.ssh/config; Dotbot manages the symlinked config file.

set -euo pipefail
setopt NULL_GLOB

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "🔐 SSH Setup Wizard"
echo "══════════════════════════════════════════════════════════════════════"

# ──────────────────────────────────────────────────────────────────────
# 📁 Paths & constants
# ──────────────────────────────────────────────────────────────────────
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

ONEP_APP="/Applications/1Password.app"
# Preferred stable symlink that your SSH config uses:
ONEP_SOCKET="$HOME/.1password/agent.sock"
# Actual app socket (moves between versions; we normalize via the symlink above):
REAL_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
LINK_DIR="$HOME/.1password"
LINK="$LINK_DIR/agent.sock"

GITHUB_HOST="github.com"
GITHUB_KEYS_URL="https://github.com/settings/keys"

IS_MACOS=0
[[ "$(uname -s)" = "Darwin" ]] && IS_MACOS=1

# ──────────────────────────────────────────────────────────────────────
# 📦 Prep & permissions
# ──────────────────────────────────────────────────────────────────────
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ ! -f "$SSH_CONFIG" && ! -L "$SSH_CONFIG" ]]; then
  echo "⚠️  ~/.ssh/config not found. Dotbot should link it from your dotfiles."
fi

umask 077
# Harden config (follow symlink to real file if present)
if [[ -L "$SSH_CONFIG" ]]; then
  _tgt="$(readlink "$SSH_CONFIG")"
  if [[ "$_tgt" != /* ]]; then
    _tgt="$(cd "$(dirname "$SSH_CONFIG")" && cd "$(dirname "$_tgt")" && pwd)/$(basename "$_tgt")"
  fi
  [[ -f "$_tgt" ]] && chmod 600 "$_tgt"
elif [[ -f "$SSH_CONFIG" ]]; then
  chmod 600 "$SSH_CONFIG"
fi

# Normalize key/known_hosts perms (safe to run repeatedly)
for _k in "$SSH_DIR"/id_*; do
  [[ -f "$_k" && "$_k" != *.pub ]] && chmod 600 "$_k"
done
for _p in "$SSH_DIR"/id_*.pub; do
  [[ -f "$_p" ]] && chmod 644 "$_p"
done
[[ -f "$SSH_DIR/known_hosts" ]] && chmod 644 "$SSH_DIR/known_hosts"

# ──────────────────────────────────────────────────────────────────────
# 1) Prefer 1Password SSH Agent (create/refresh symlink if agent is active)
# ──────────────────────────────────────────────────────────────────────
USING_ONEP=0
if [[ -d "$ONEP_APP" ]]; then
  echo "✅ 1Password app found."

  if [[ -S "$ONEP_SOCKET" || -S "$REAL_SOCK" ]]; then
    # Ensure ~/.1password/agent.sock → REAL_SOCK
    if [[ -S "$REAL_SOCK" ]]; then
      mkdir -p "$LINK_DIR"
      if [[ -L "$LINK" ]]; then
        cur="$(readlink "$LINK")"
        [[ "$cur" != "$REAL_SOCK" ]] && { ln -sf "$REAL_SOCK" "$LINK"; echo "🔗 Updated symlink: $LINK -> $REAL_SOCK"; }
      elif [[ -e "$LINK" ]]; then
        echo "⚠️  $LINK exists and is not a symlink; leaving as-is."
      else
        ln -s "$REAL_SOCK" "$LINK"; echo "🔗 Created symlink: $LINK -> $REAL_SOCK"
      fi
    fi
    echo "✅  1Password SSH Agent socket detected."
    USING_ONEP=1
  else
    echo "ℹ️  1Password SSH Agent not detected."
    echo "👉 Enable it: 1Password → Settings → Developer → “Use 1Password as SSH Agent”."
    read "ans?🕹️  Open 1Password now? (Y/n): "
    [[ -z "${ans:-}" || "$ans" = [Yy] ]] && { open -ga "$ONEP_APP" || true; }
    read "ack?⏸️  Press [Enter] after enabling the 1Password SSH Agent…"

    # Give it a moment to create the socket
    tries=0
    until [[ -S "$ONEP_SOCKET" || -S "$REAL_SOCK" || $tries -ge 12 ]]; do
      ((++tries)); printf "\r⏳ Waiting for 1Password SSH agent… (%ss)" $((tries)); sleep 1
    done
    echo

    if [[ -S "$ONEP_SOCKET" || -S "$REAL_SOCK" ]]; then
      echo "✅  Detected 1Password agent socket."
      USING_ONEP=1
      if [[ -S "$REAL_SOCK" ]]; then
        mkdir -p "$LINK_DIR"
        if [[ -L "$LINK" ]]; then
          cur="$(readlink "$LINK")"
          [[ "$cur" != "$REAL_SOCK" ]] && { ln -sf "$REAL_SOCK" "$LINK"; echo "🔗 Updated symlink: $LINK -> $REAL_SOCK"; }
        elif [[ -e "$LINK" ]]; then
          echo "⚠️  $LINK exists and is not a symlink; leaving as-is."
        else
          ln -s "$REAL_SOCK" "$LINK"; echo "🔗 Created symlink: $LINK -> $REAL_SOCK"
        fi
      fi
    else
      echo "⚠️  Still no agent socket — will use macOS agent fallback."
      USING_ONEP=0
    fi
  fi
else
  echo "ℹ️  1Password app not installed (Homebrew step should install it on fresh machines)."
fi

# ──────────────────────────────────────────────────────────────────────
# 2) Fallback: macOS agent + local key (if 1Password is not active)
# ──────────────────────────────────────────────────────────────────────
if [[ "$USING_ONEP" -eq 0 ]]; then
  KEY="$SSH_DIR/id_ed25519"
  if [[ -f "$KEY" ]]; then
    echo "✅ Found local key: $KEY"
    chmod 600 "$KEY" 2>/dev/null || true
    [[ -f "${KEY}.pub" ]] && chmod 644 "${KEY}.pub" 2>/dev/null || true
    if [[ $IS_MACOS -eq 1 ]]; then
      ssh-add --apple-use-keychain "$KEY" || true
    else
      ssh-add "$KEY" || true
    fi
  else
    echo "🔑 No local SSH key found at $KEY."
    read "gen?➕ Generate a new Ed25519 key now? (Y/n): "
    if [[ -z "${gen:-}" || "$gen" = [Yy] ]]; then
      HOSTLABEL="$(scutil --get ComputerName 2>/dev/null || hostname)"
      ssh-keygen -t ed25519 -C "Mateo ${HOSTLABEL} (Personal)" -f "$KEY"
      chmod 600 "$KEY" 2>/dev/null || true
      chmod 644 "${KEY}.pub" 2>/dev/null || true
      if [[ $IS_MACOS -eq 1 ]]; then
        ssh-add --apple-use-keychain "$KEY" || true
      else
        ssh-add "$KEY" || true
      fi
      echo ""
      echo "📋 Public key to add to GitHub:"
      echo "----8<----"
      cat "${KEY}.pub"
      echo "----8<----"
      command -v pbcopy >/dev/null 2>&1 && { pbcopy < "${KEY}.pub"; echo "✅ Copied public key to clipboard."; }
      read "added?⏸️  Press [Enter] after you’ve added the public key to GitHub ($GITHUB_KEYS_URL)…"
    else
      echo "⏭️  Skipping key generation — ensure you already have a working key."
    fi
  fi
else
  echo "🔒 Using 1Password SSH Agent."
  echo "👉 Ensure your GitHub SSH key is in 1Password and the PUBLIC key is in GitHub."
  echo "   (If you use a non-Default/Personal vault, set it in ~/.config/1Password/ssh/agent.toml)"
  read "open1p?🌐 Open GitHub SSH keys page? (Y/n): "
  [[ -z "${open1p:-}" || "$open1p" = [Yy] ]] && { open "$GITHUB_KEYS_URL" || true; }
  read "proceed?⏸️  Press [Enter] when your GitHub key is confirmed in 1Password & on GitHub…"
fi

# ──────────────────────────────────────────────────────────────────────
# 3) Verification (truth-revealing)
# ──────────────────────────────────────────────────────────────────────
echo ""
echo "🔎 Verification: effective SSH settings for github.com"
echo "— 1Password agent socket present? " $([[ -S "$ONEP_SOCKET" || -S "$REAL_SOCK" ]] && echo "YES" || echo "NO")
echo "— SSH_AUTH_SOCK (current shell): ${SSH_AUTH_SOCK:-<unset>}"
if command -v ssh >/dev/null 2>&1; then
  echo "— Resolved options (ssh -G github.com):"
  ssh -G github.com | grep -E '^(identityagent|identityfile|identitiesonly|user) ' || true
fi

# Show what the 1Password agent knows, without changing your environment:
if [[ -S "$ONEP_SOCKET" ]]; then
  echo "— Keys visible in 1Password agent (ssh-add -l via 1P socket):"
  SSH_AUTH_SOCK="$ONEP_SOCKET" ssh-add -l 2>/dev/null || echo "  (no keys reported by 1Password agent)"
fi

echo ""
echo "🧪 Testing SSH to GitHub (${GITHUB_HOST}) — “no shell access” on success is normal…"
set +e
ssh -T "git@${GITHUB_HOST}"
STATUS=$?
set -e

if [[ $STATUS -eq 0 || $STATUS -eq 1 ]]; then
  echo "🎉 SSH looks good!"
else
  echo "⚠️  GitHub auth didn’t succeed (exit $STATUS). Common fixes:"
  echo "   • 1Password: enable SSH Agent; ensure key in vault; public key on GitHub."
  echo "   • macOS key: ensure public key is added at $GITHUB_KEYS_URL."
  echo "   • Remotes:  git remote -v  (should be git@github.com:… for SSH)."
fi

echo "✅ SSH setup wizard finished."