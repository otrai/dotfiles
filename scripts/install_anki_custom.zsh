#!/bin/zsh

# ---------------------------------------------------
# 🧠 Install Anki 24.06.3 for compatibility with Butler
# ---------------------------------------------------

# Set required variables
ANKI_VERSION="24.06.3"
ANKI_DMG_URL="https://github.com/ankitects/anki/releases/download/$ANKI_VERSION/anki-$ANKI_VERSION-mac-apple-qt6.dmg"
DMG_NAME="anki-$ANKI_VERSION.dmg"
MOUNT_POINT="/Volumes/Anki"

BUTLER_ADDON="$HOME/Library/Mobile Documents/com~apple~CloudDocs/03 Resources/Software/butler.ankiaddon"
CLOZE_ADDON="$HOME/Library/Mobile Documents/com~apple~CloudDocs/03 Resources/Software/cloze_overlapper.ankiaddon"

# Require sudo for /Applications write access
echo "🔐 This script requires sudo to install to /Applications"
sudo -v

# Download Anki
echo "📦 Downloading Anki $ANKI_VERSION..."
curl -L -o "/tmp/$DMG_NAME" "$ANKI_DMG_URL"

# Mount the DMG
echo "📂 Mounting Anki disk image..."
hdiutil attach "/tmp/$DMG_NAME" -mountpoint "$MOUNT_POINT"

# Copy Anki to Applications
echo "📥 Installing Anki to /Applications..."
sudo cp -R "$MOUNT_POINT/Anki.app" /Applications/

# Unmount the DMG
echo "💾 Unmounting disk image..."
hdiutil detach "$MOUNT_POINT"

# Cleanup
echo "🧼 Cleaning up..."
rm "/tmp/$DMG_NAME"

# ---------------------------------------------------
# 🧠 Post-install Instructions (manual steps required)
# ---------------------------------------------------
echo "✅ Anki $ANKI_VERSION installed successfully!"
echo "📌 Follow the steps below to complete setup."

# Reminder to sign in first
echo ""
echo "🧠 Reminder: Before installing add-ons..."
echo "🔐 Please sign in to BOTH your old and new AnkiWeb accounts if needed:"
echo "   1. Open Anki → Preferences → 'Syncing'"
echo "   2. Ensure you're signed in and syncing is complete"
echo "   3. Then quit Anki before continuing with add-on installation"
echo ""
read "proceed?Press [Enter] to continue once you're signed in and syncing is complete..."

# Launch Butler add-on installer
if [[ -f "$BUTLER_ADDON" ]]; then
  echo "📦 Launching Butler add-on installer..."
  open "$BUTLER_ADDON"
  read "ack1?Press [Enter] after installing Butler to continue..."
else
  echo "⚠️ Butler add-on not found at:"
  echo "   $BUTLER_ADDON"
fi

# Launch Cloze Overlapper add-on installer
if [[ -f "$CLOZE_ADDON" ]]; then
  echo "📦 Launching Cloze Overlapper add-on installer..."
  open "$CLOZE_ADDON"
  read "ack2?Press [Enter] after installing Cloze Overlapper to finish..."
else
  echo "⚠️ Cloze Overlapper add-on not found at:"
  echo "   $CLOZE_ADDON"
fi

# Reminder: Highlight Code add-on
echo ""
echo "🧠 Manual step: Install the Highlight Code add-on from AnkiWeb:"
echo "   1. Open Anki"
echo "   2. Go to Tools → Add-ons → Get Add-ons…"
echo "   3. Paste this ID: 112228974"
echo "   4. Click OK, then restart Anki"

# Change Anki Settings
echo ""
echo "🎨 Enable the 'Custom Background Image and Gear Icon' add-on:"
echo "   1. Open Anki → Tools → Add-ons"
echo "   2. Look for 'Custom Background Image and Gear Icon'"
echo "   3. Select it and click 'Toggle Enabled'"
echo "   4. Restart Anki for changes to apply"

echo ""
echo "🖼️ Configure the custom background image:"
echo "   - Open Anki → AnKing → 'Custom Background Image and Gear Icon'"
echo "   - Set the background to an image in the backgrounds folder"
echo "   - Enable show background image in reviewer, toolbar, and toolbar top/bottom"

echo ""
echo "🗂️ Optional: Change Browser layout to vertical view:"
echo "   1. Open the Browser"
echo "   2. Go to View → Layout → Vertical"

# Completion message
echo ""
echo "🎉 Setup complete! Launch or restart Anki if it’s not already running."
echo ""