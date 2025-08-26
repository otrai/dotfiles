#!/bin/zsh
# 🔐 setup_ssh.zsh — interactive SSH setup wizard
# - Prefers 1Password SSH Agent (with clear enable steps + visible wait)
# - Falls back to macOS agent: generates key if missing, loads into keychain
# - Never stores private keys in your repo
# - Prints every manual step, pauses, and ends with a verified GitHub auth test
# -----------------------------------------------------------------------------

set -euo pipefail

# ⏭️ Respect Dotbot dry-run guard
[[ -n "${SKIP_SHELL:-}" ]] && { echo "⏭️  SKIP_SHELL set — skipping $0"; exit 0; }

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "🔐 SSH Setup Wizard"
echo "══════════════════════════════════════════════════════════════════════"

# 📁 Basics
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
ONEP_APP="/Applications/1Password.app"
ONEP_SOCKET="$HOME/.1password/agent.sock"
GITHUB_HOST="github.com"
GITHUB_KEYS_URL="https://github.com/settings/keys"

# OS guard for keychain flag
IS_MACOS=0
[[ "$(uname -s)" = "Darwin" ]] && IS_MACOS=1

# Ensure ~/.ssh exists + sane perms
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Nice UX: warn if ~/.ssh/config is missing (Dotbot should create the symlink)
if [[ ! -f "$SSH_CONFIG" && ! -L "$SSH_CONFIG" ]]; then
  echo "⚠️  ~/.ssh/config not found. Your Dotbot link step should create it from dotfiles."
  echo "   Proceeding anyway (agent/key will still be set up)."
fi

# ──────────────────────────────────────────────────────────────────────
# 1) Prefer 1Password SSH Agent
# ──────────────────────────────────────────────────────────────────────
USING_ONEP=0
if [[ -d "$ONEP_APP" ]]; then
  echo "✅ 1Password app found."
  if [[ -S "$ONEP_SOCKET" ]]; then
    echo "✅ 1Password SSH Agent is already active."
    USING_ONEP=1
  else
    echo "ℹ️  1Password SSH Agent not detected."
    echo "👉 Do this now:"
    echo "   1) Open 1Password"
    echo "   2) Settings → Developer"
    echo "   3) Enable: “Use 1Password as SSH Agent”"
    echo ""
    read "ans?🕹️  Open 1Password for you now? (Y/n): "
    if [[ -z "$ans" || "$ans" = [Yy] ]]; then
      open -ga "$ONEP_APP" || true
    fi
    read "ack?⏸️  Press [Enter] after you’ve enabled the 1Password SSH Agent…"

    # Visible wait loop for the agent socket
    tries=0
    until [[ -S "$ONEP_SOCKET" || $tries -ge 12 ]]; do
      ((++tries)); printf "\r⏳ Waiting for 1Password SSH agent… (%ss)" $((tries)); sleep 1
    done
    echo

    if [[ -S "$ONEP_SOCKET" ]]; then
      echo "✅ Detected 1Password agent socket at $ONEP_SOCKET"
      USING_ONEP=1
    else
      echo "⚠️  Still no agent socket detected — we’ll use the macOS agent fallback."
      USING_ONEP=0
    fi
  fi
else
  echo "ℹ️  1Password app not installed (Homebrew step installs it on fresh machines)."
fi

# ──────────────────────────────────────────────────────────────────────
# 2) If NOT using 1Password, ensure a local key exists (macOS agent path)
# ──────────────────────────────────────────────────────────────────────
if [[ "$USING_ONEP" -eq 0 ]]; then
  KEY="$SSH_DIR/id_ed25519"
  if [[ -f "$KEY" ]]; then
    echo "✅ Found local key: $KEY"
    # secure perms
    chmod 600 "$KEY" 2>/dev/null || true
    [[ -f "${KEY}.pub" ]] && chmod 644 "${KEY}.pub" 2>/dev/null || true
    # add to agent (macOS vs other)
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
    if [[ -z "$gen" || "$gen" = [Yy] ]]; then
      HOSTLABEL="$(scutil --get ComputerName 2>/dev/null || hostname)"
      # NOTE: no -N "" → ssh-keygen will prompt for a passphrase
      ssh-keygen -t ed25519 -C "Mateo ${HOSTLABEL} (Personal)" -f "$KEY"
      chmod 600 "$KEY" 2>/dev/null || true
      chmod 644 "${KEY}.pub" 2>/dev/null || true

      # Load into agent (Keychain on macOS will remember the passphrase after first use)
      if [[ $IS_MACOS -eq 1 ]]; then
        ssh-add --apple-use-keychain "$KEY" || true
      else
        ssh-add "$KEY" || true
      fi

      echo ""
      echo "🔏 Passphrase reminder"
      echo "   • Save this new SSH key’s passphrase in 1Password so you never lose it."
      read "open1p?🔐 Open 1Password now to save the passphrase? (Y/n): "
      if [[ -z "$open1p" || "$open1p" = [Yy] ]]; then
        open -ga "$ONEP_APP" || true
      fi

      echo ""
      echo "📋 Public key that must be added to GitHub (Settings → SSH keys):"
      echo "----8<----"
      cat "${KEY}.pub"
      echo "----8<----"
      if command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "${KEY}.pub" && echo "✅ Copied public key to clipboard."
      fi
      read "added?⏸️  Press [Enter] after you’ve saved the passphrase in 1Password and added the public key to GitHub…"
    else
      echo "⏭️  Skipping key generation — ensure you already have a working key."
    fi
  fi
else
  echo "🔒 Using 1Password SSH Agent."
  echo "👉 Make sure your GitHub SSH key exists in 1Password and its *public key* is added to GitHub."
  read "open1p?🌐 Open GitHub SSH keys page for a quick check? (Y/n): "
  if [[ -z "$open1p" || "$open1p" = [Yy] ]]; then
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
# 3) Final verification (GitHub returns 1 on success w/ 'no shell access')
# ──────────────────────────────────────────────────────────────────────
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
  echo "   • If using 1Password: ensure the SSH Agent is enabled and the correct key is in your vault."
  echo "   • If using macOS key: ensure the public key is added at $GITHUB_KEYS_URL."
  echo "   • Confirm remotes use SSH:  git remote -v  (should be git@github.com:…)"
fi

echo "✅ SSH setup wizard finished."