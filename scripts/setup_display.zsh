#!/bin/zsh

# ---------------------------------------------
# 🖥️ Detect Mac model and apply display settings
# ---------------------------------------------

MAC_MODEL=$(sysctl -n hw.model)

if [[ "$MAC_MODEL" == "MacBookPro"* ]]; then
  echo "💻 MacBook Pro detected — applying MacBook display settings..."
  ./scripts/setup_display_macbookpro.zsh
elif [[ "$MAC_MODEL" == "MacPro"* || "$MAC_MODEL" == "MacStudio"* ]]; then
  echo "🖥️ Desktop Mac detected — applying Pro Display XDR settings..."
  ./scripts/setup_display_xdr.zsh
else
  echo "⚠️ Unknown machine type ($MAC_MODEL) — skipping display setup."
fi