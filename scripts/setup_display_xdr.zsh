#!/usr/bin/env zsh

# ---------------------------------------------
# 🖥️ Setup Display Resolution for Pro Display XDR
# ---------------------------------------------

# setup_display_xdr.zsh — set a readable resolution on the main display (XDR or any external)
set -euo pipefail

# 1) Ensure displayplacer exists
if ! command -v displayplacer >/dev/null 2>&1; then
  echo "⚠️ displayplacer not installed; skipping XDR setup."
  exit 0
fi

# 2) Get the block for the main display (records separated by blank lines)
block="$(displayplacer list | awk -v RS='' '/main display/ {print; exit}')"
[[ -z "$block" ]] && { echo "ℹ️ No main display yet; skipping."; exit 0; }

# 3) Contextual id from the same block
main_ctx_id="$(printf "%s" "$block" | awk '/Contextual screen id:/ {print $NF; exit}')"
[[ -z "${main_ctx_id:-}" ]] && { echo "ℹ️ Could not detect contextual id; skipping."; exit 0; }

# 4) Choose preferred resolutions (bigger UI first)
prefs=("1920x1080" "2560x1440" "3008x1692")

# Extract this display's rotation-0 modes from the same block
modes="$(printf "%s" "$block" | awk '/Resolutions for rotation 0:/{flag=1;next}flag')"

pick=""
for want in "${prefs[@]}"; do
  if printf "%s\n" "$modes" | grep -q "res:${want} .*hz:60 .*scaling:on"; then
    pick="res:${want} hz:60 color_depth:7 scaling:on"
    break
  fi
  if printf "%s\n" "$modes" | grep -q "res:${want} .*hz:60 "; then
    pick="res:${want} hz:60 color_depth:7"
    break
  fi
done

[[ -z "$pick" ]] && { echo "ℹ️ Preferred resolutions not found; leaving current settings."; exit 0; }

# 5) Apply
cmd=(displayplacer "id:${main_ctx_id} ${pick} enabled:true origin:(0,0) degree:0")
echo "🖥️ Applying: ${cmd[@]}"
"${cmd[@]}"

echo "✅ XDR display set to ${pick#res:}"