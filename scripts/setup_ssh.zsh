#!/usr/bin/env zsh
# 🔐 setup_ssh.zsh — interactive SSH setup wizard
# - Prefers 1Password SSH Agent (if active) and normalizes its socket symlink
# - Falls back to macOS agent: generates key if missing, loads into Keychain
# - Hardens permissions (dir 700, config 600 incl. symlink target, keys normalized)
# - Appends IdentityAgent only when 1Password agent is active (idempotent)
# - Prints effective agent/key and verifies GitHub access
# -----------------------------------------------------------------------------

set -euo pipefail
setopt NULL_GLOB

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "🔐 SSH Setup Wizard"
echo "══════════════════════════════════════════════════════════════════════"

# 📁 Basics
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
ONEP_APP="/Applications/1Password.app"
# Compatibility symlink path we prefer to use in config:
ONEP_SOCKET="$HOME/.1password/agent.sock"
# Real socket path inside 1Password's container:
REAL_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
LINK_DIR="$HOME/.1password"
LINK="$LINK_DIR/agent.sock"

GITHUB_HOST="github.com"
GITHUB_KEYS_URL="https://github.com/settings/keys"

# OS guard for keychain flag
IS_MACOS=0
[[ "$(uname -s)" = "Darwin" ]] && IS_MACOS=1

# Ensure ~/.ssh exists + base perms
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Warn if ~/.ssh/config missing (Dotbot should link this from the repo)
if [[ ! -f "$SSH_CONFIG" && ! -L "$SSH_CONFIG" ]]; then
  echo "⚠️  ~/.ssh/config not found. Your Dotbot link step should create it from dotfiles."
  echo "   Proceeding anyway (agent/key will still be set up)."
fi

# --- 🔒 Permission hardening (idempotent) -------------------------------------
umask 077  # new files default to private perms

# If ~/.ssh/config is a symlink, harden the TARGET; else harden the file
if [[ -L "$SSH_CONFIG" ]]; then
  _tgt="$(readlink "$SSH_CONFIG")"
  if [[ "$_tgt" != /* ]]; then
    _tgt="$(cd "$(dirname "$SSH_CONFIG")" && cd "$(dirname "$_tgt")" && pwd)/$(basename "$_tgt")"
  fi
  [[ -f "$_tgt" ]] && chmod 600 "$_tgt"
elif [[ -f "$SSH_CONFIG" ]]; then
  chmod 600 "$SSH_CONFIG"
fi

# Normalize key & known_hosts perms (safe every run)
for _k in "$SSH_DIR"/id_*; do
  [[ -f "$_k" && "$_k" != *.pub ]] && chmod 600 "$_k"
done
for _p in "$SSH_DIR"/id_*.pub; do
  [[ -f "$_p" ]] && chmod 644 "$_p"
done
[[ -f "$SSH_DIR/known_hosts" ]] && chmod 644 "$SSH_DIR/known_hosts"

# ──────────────────────────────────────────────────────────────────────
# 1) Prefer 1Password SSH Agent
# ──────────────────────────────────────────────────────────────────────
USING_ONEP=0
if [[ -d "$ONEP_APP" ]]; then
  echo "✅ 1Password app found."

  # Treat agent as active if either the symlink OR the real socket exists
  if [[ -S "$ONEP_SOCKET" || -S "$REAL_SOCK" ]]; then
    # Ensure ~/.1password/agent.sock symlink exists / is correct
    if [[ -S "$REAL_SOCK" ]]; then
      mkdir -p "$LINK_DIR"
      if [[ -L "$LINK" ]]; then
        current="$(readlink "$LINK")"
        if [[ "$current" != "$REAL_SOCK" ]]; then
          ln -sf "$REAL_SOCK" "$LINK"
          echo "🔗 Updated symlink: $LINK -> $REAL_SOCK"
        fi
      elif [[ -e "$LINK" ]]; then
        echo "⚠️  $LINK exists and is not a symlink; leaving it unchanged."
      else
        ln -s "$REAL_SOCK" "$LINK"
        echo "🔗 Created symlink: $LINK -> $REAL_SOCK"
      fi
    fi

    echo "✅ 1Password SSH Agent is already active."
    USING_ONEP=1

  else
    echo "ℹ️  1Password SSH Agent not detected."
    echo "👉 Enable it: 1Password → Settings → Developer → “Use 1Password as SSH Agent”"
    echo ""
    read "ans?🕹️  Open 1Password now? (Y/n): "
    if [[ -z "${ans:-}" || "$ans" = [Yy] ]]; then
      open -ga "$ONEP_APP" || true
    fi
    read "ack?⏸️  Press [Enter] after enabling the 1Password SSH Agent…"

    # Wait briefly for the agent socket
    tries=0
    until [[ -S "$ONEP_SOCKET" || -S "$REAL_SOCK" || $tries -ge 12 ]]; do
      ((++tries)); printf "\r⏳ Waiting for 1Password SSH agent… (%ss)" $((tries)); sleep 1
    done
    echo

    if [[ -S "$ONEP_SOCKET" || -S "$REAL_SOCK" ]]; then
      echo "✅ Detected 1Password agent socket."
      USING_ONEP=1

      # Create/refresh the symlink now that the agent is up
      if [[ -S "$REAL_SOCK" ]]; then
        mkdir -p "$LINK_DIR"
        if [[ -L "$LINK" ]]; then
          current="$(readlink "$LINK")"
          if [[ "$current" != "$REAL_SOCK" ]]; then
            ln -sf "$REAL_SOCK" "$LINK"
            echo "🔗 Updated symlink: $LINK -> $REAL_SOCK"
          fi
        elif [[ -e "$LINK" ]]; then
          echo "⚠️  $LINK exists and is not a symlink; leaving it unchanged."
        else
          ln -s "$REAL_SOCK" "$LINK"
          echo "🔗 Created symlink: $LINK -> $REAL_SOCK"
        fi
      fi

    else
      echo "⚠️  Still no agent socket detected — will use macOS agent fallback."
      USING_ONEP=0
    fi
  fi
else
  echo "ℹ️  1Password app not installed (Homebrew step installs it on fresh machines)."
fi

# If 1Password agent is active, ensure IdentityAgent line exists (append once)
if [[ "$USING_ONEP" -eq 1 ]]; then
  _CFG="$SSH_CONFIG"
  if [[ -L "$SSH_CONFIG" ]]; then
    _tgt="$(readlink "$SSH_CONFIG")"
    [[ "$_tgt" != /* ]] && _tgt="$(cd "$(dirname "$SSH_CONFIG")" && cd "$(dirname "$_tgt")" && pwd)/$(basename "$_tgt")"
    _CFG="$_tgt"
  fi
  grep -qE '^\s*Host\s+\*' "$_CFG" 2>/dev/null || echo "Host *" >> "$_CFG"
  grep -qxF "  IdentityAgent ~/.1password/agent.sock" "$_CFG" 2>/dev/null || \
    echo "  IdentityAgent ~/.1password/agent.sock" >> "$_CFG"
fi

# ──────────────────────────────────────────────────────────────────────
# 2) If NOT using 1Password, ensure a local key exists (macOS agent path)
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
    echo "🧩 You’ll be prompted to create one and choose a passphrase."
    echo "   • Use a strong passphrase you can remember (or store)."
    echo "   • You’ll enter it once now; macOS Keychain will remember it for SSH."
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
      echo "📋 Public key to add to GitHub (Settings → SSH keys):"
      echo "----8<----"
      cat "${KEY}.pub"
      echo "----8<----"
      if command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "${KEY}.pub" && echo "✅ Copied public key to clipboard."
      fi
      read "added?⏸️  Press [Enter] after you’ve added the public key to GitHub…"
    else
      echo "⏭️  Skipping key generation — ensure you already have a working key."
    fi
  fi
else
  echo "🔒 Using 1Password SSH Agent."
  echo "👉 Ensure your GitHub SSH key exists in 1Password and the *public key* is added to GitHub."
  read "open1p?🌐 Open GitHub SSH keys page? (Y/n): "
  if [[ -z "${open1p:-}" || "$open1p" = [Yy] ]]; then
    open "$GITHUB_KEYS_URL" || true
  fi
  read "proceed?⏸️  Press [Enter] when your GitHub key is confirmed in 1Password & on GitHub…"
fi

# Helpful tip if repo remote uses HTTPS
if command -v git >/dev/null 2>&1; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
    [[ "$ORIGIN" == https://* ]] && echo "ℹ️  Tip: switch to SSH remote →  git remote set-url origin git@github.com:<user>/<repo>.git"
  fi
fi

# ──────────────────────────────────────────────────────────────────────
# 3) Verification: show effective config and test GitHub auth
# ──────────────────────────────────────────────────────────────────────
echo ""
echo "🔎 Verification: effective SSH settings for github.com"
echo "— 1Password agent socket present? " $([[ -S "$ONEP_SOCKET" || -S "$REAL_SOCK" ]] && echo "YES" || echo "NO")
echo "— SSH_AUTH_SOCK: ${SSH_AUTH_SOCK:-<unset>}"
if command -v ssh >/dev/null 2>&1; then
  echo "— Effective IdentityAgent / IdentityFile:"
  ssh -G github.com | grep -E '^(identityagent|identityfile) ' || true
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
  echo "   • 1Password: ensure SSH Agent is enabled & correct key in vault."
  echo "   • macOS key: ensure the public key is added at $GITHUB_KEYS_URL."
  echo "   • Remotes:  git remote -v  (should be git@github.com:…)"
fi

echo "✅ SSH setup wizard finished."