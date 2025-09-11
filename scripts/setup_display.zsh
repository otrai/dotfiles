#!/usr/bin/env zsh

# ---------------------------------------------
# 🖥️ Detect Mac model and apply display settings
# ---------------------------------------------

# 🖥️ Decide which display profile to apply, with a safe generic fallback
set -euo pipefail

# Resolve script dir (so calls work from anywhere)
SCRIPT_DIR="$(cd -- "$(dirname "${0}")" >/dev/null 2>&1 && pwd)"
XDR="${SCRIPT_DIR}/setup_display_xdr.zsh"
MBP="${SCRIPT_DIR}/setup_display_macbookpro.zsh"   # <-- make sure this filename matches your repo

# Ensure displayplacer exists
if ! command -v displayplacer >/dev/null 2>&1; then
  echo "⚠️ displayplacer not installed; skipping display setup."
  exit 0
fi

# Prefer capability detection: if main display exposes 6K, use XDR profile
block="$(displayplacer list | awk -v RS='' '/main display/ {print; exit}')"
if [[ -n "${block}" && "${block}" == *"6016x3384"* ]]; then
  echo "🖥️ Pro Display XDR (6K) detected — using XDR profile."
  exec "${XDR}"
fi

# Fallback to machine family (Studio/Pro use these identifiers; MacBookPro matches literally)
MAC_MODEL="$(sysctl -n hw.model 2>/dev/null || true)"
if [[ "${MAC_MODEL}" == MacBookPro* ]]; then
  echo "💻 MacBook Pro detected — using built-in display profile."
  exec "${MBP}"
fi
if [[ "${MAC_MODEL}" == MacPro* || "${MAC_MODEL}" == Mac13,* || "${MAC_MODEL}" == Mac14,* || "${MAC_MODEL}" == Mac15,* ]]; then
  echo "🖥️ Desktop Mac detected — using XDR/external profile."
  exec "${XDR}"
fi

# --- Generic fallback for any other display ---
if [[ "${DOTFILES_DISPLAY_SKIP:-0}" = "1" ]]; then
  echo "⏭️ DOTFILES_DISPLAY_SKIP=1 — skipping display setup."
  exit 0
fi

# If we got here: pick a readable default on the current main display
if [[ -z "$block" ]]; then
  echo "ℹ️ No main display detected (headless/SSH?) — skipping."
  exit 0
fi
main_ctx_id="$(printf "%s" "$block" | awk '/Contextual screen id:/ {print $NF; exit}')"
if [[ -z "$main_ctx_id" ]]; then
  echo "ℹ️ Could not detect contextual id; skipping."
  exit 0
fi

want_res="${DOTFILES_DISPLAY_RES:-1920x1080}"
want_hz="${DOTFILES_DISPLAY_HZ:-60}"
want_scaling="${DOTFILES_DISPLAY_SCALING:-on}"
modes="$(printf "%s" "$block" | awk '/Resolutions for rotation 0:/{flag=1;next}flag')"

if printf "%s\n" "$modes" | grep -q "res:${want_res} .*hz:${want_hz} .*scaling:${want_scaling}"; then
  cmd=(displayplacer "id:${main_ctx_id} res:${want_res} hz:${want_hz} color_depth:7 scaling:${want_scaling} enabled:true origin:(0,0) degree:0")
  echo "🖥️ Applying generic display: ${cmd[@]}"
  "${cmd[@]}"
  echo "✅ Display set to ${want_res}@${want_hz} scaling:${want_scaling}"
else
  echo "ℹ️ ${want_res}@${want_hz} scaling:${want_scaling} not supported; leaving current settings."
fi