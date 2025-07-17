#!/bin/zsh

# ---------------------------------------------
# 🎯 Setup Display Resolution for MacBook Pro
# ---------------------------------------------

# Required: `displayplacer` must already be installed
if ! command -v displayplacer &>/dev/null; then
  echo "❌ displayplacer is not installed. Please install it via Homebrew first."
  exit 1
fi

# Step 1: Detect the Display ID for the built-in MacBook screen
DISPLAY_ID=$(displayplacer list | awk '
  /Persistent screen id:/ {id = $NF}
  /MacBook built in screen/ {print id}
')

# Step 2: Set default resolution configuration (customize this if needed)
RES="1496x967"
HZ="120"
COLOR="8"
SCALING="on"
ORIGIN="(0,0)"
ROTATION="0"

# Step 3: Apply the resolution
if [[ -n "$DISPLAY_ID" ]]; then
  echo "🖥️ Applying resolution $RES to MacBook Pro built-in display (ID: $DISPLAY_ID)..."
  displayplacer "id:$DISPLAY_ID res:$RES hz:$HZ color_depth:$COLOR enabled:true scaling:$SCALING origin:$ORIGIN degree:$ROTATION"
  echo "✅ Display resolution applied successfully."
else
  echo "❌ Could not detect the MacBook built-in display ID."
fi