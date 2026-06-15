#!/bin/zsh
# 📦 setup_repos.zsh — clone your active GitHub repos into ~/code
# Discovers repos with the GitHub CLI, so there is NO list to maintain:
#   • Skips forks (--source)
#   • Skips archived repos (--no-archived)
#   • Skips infrastructure repos listed in EXCLUDE (e.g. dotfiles)
#   • Skips repos already cloned (idempotent — safe to re-run)

set -euo pipefail

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "📦 Repository Setup"
echo "══════════════════════════════════════════════════════════════════════"

# ──────────────────────────────────────────────────────────────────────
# ⚙️  Settings (the only lines you'd ever change)
# ──────────────────────────────────────────────────────────────────────
CODE_DIR="$HOME/code"        # where your projects live
GITHUB_USER="otrai"          # GitHub account to mirror
EXCLUDE=("dotfiles")         # repos to NOT clone here (they live elsewhere)

# ──────────────────────────────────────────────────────────────────────
# 🔎 Preflight: make sure gh exists and is logged in
# ──────────────────────────────────────────────────────────────────────
if ! command -v gh >/dev/null 2>&1; then
  echo "❌ GitHub CLI (gh) not found — it should be installed via the Brewfile."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "🔐 gh is not authenticated — launching 'gh auth login'…"
  gh auth login
fi

# ──────────────────────────────────────────────────────────────────────
# 📂 Make sure the code directory exists
# ──────────────────────────────────────────────────────────────────────
mkdir -p "$CODE_DIR"
echo "📂 Projects will live in: $CODE_DIR"

# ──────────────────────────────────────────────────────────────────────
# ⬇️  Discover active repos and clone any that are missing
# ──────────────────────────────────────────────────────────────────────
echo "🔎 Fetching active (non-fork, non-archived) repos for '$GITHUB_USER'…"
repos=$(gh repo list "$GITHUB_USER" --source --no-archived --limit 1000 --json name --jq '.[].name')

for name in ${(f)repos}; do
  # Skip anything in the EXCLUDE list
  skip=0
  for ex in "${EXCLUDE[@]}"; do
    [[ "$name" == "$ex" ]] && skip=1
  done
  if (( skip )); then
    echo "⏭️  Skipping $name (excluded)."
    continue
  fi

  dest="$CODE_DIR/$name"
  if [[ -d "$dest" ]]; then
    echo "✅ $name already present — skipping."
  else
    echo "⬇️  Cloning $name…"
    git clone "git@github.com:$GITHUB_USER/$name.git" "$dest"
  fi
done

echo ""
echo "🎉 Repository setup complete. Your projects are in $CODE_DIR"