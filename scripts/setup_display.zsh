#!/bin/zsh

echo "🖥️ Configuring display scaling using displayplacer..."

if command -v displayplacer &>/dev/null; then
  echo ""
  echo "📋 Listing your current display(s):"
  echo ""
  displayplacer list

  echo ""
  echo "👉 Copy the display ID of your main screen from above."
  echo -n "🆔 Paste the display ID here: "
  read display_id

  echo -n "📏 Desired resolution (e.g., 1440x900): "
  read resolution

  echo ""
  echo "⚙️ Applying resolution '$resolution' to display ID '$display_id'..."
  displayplacer "id:$display_id res:$resolution scaling:on"

  echo "✅ Display resolution applied."
else
  echo "⚠️ displayplacer is not installed. Skipping display configuration."
fi