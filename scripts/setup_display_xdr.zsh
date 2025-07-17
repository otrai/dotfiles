#!/bin/zsh

# ---------------------------------------------
# 🖥️ Setup Display Resolution for Pro Display XDR
# ---------------------------------------------

# Required: `displayplacer` must already be installed
if ! command -v displayplacer &>/dev/null; then
  echo "❌ displayplacer is not installed. Please install it via Homebrew first."
  exit 1
fi

# Step 1: Detect the Display ID for Pro Display XDR
DISPLAY_ID=$(displayplacer list | awk '/Pro Display XDR/{getline; print}' | grep -oE 'id:[^ ]+' | cut -d: -f2)

# Step 2: Set default resolution configuration (customize as needed)
RES="1920x1080"
HZ="60"
COLOR="8"
SCALING="on"
ORIGIN="(0,0)"
ROTATION="0"

# Step 3: Apply the resolution
if [[ -n "$DISPLAY_ID" ]]; then
  echo "🖥️ Applying resolution $RES to Pro Display XDR (ID: $DISPLAY_ID)..."
  displayplacer "id:$DISPLAY_ID res:$RES hz:$HZ color_depth:$COLOR enabled:true scaling:$SCALING origin:$ORIGIN degree:$ROTATION"
  echo "✅ Display resolution applied successfully."
else
  echo "❌ Could not detect the Pro Display XDR ID."
fi