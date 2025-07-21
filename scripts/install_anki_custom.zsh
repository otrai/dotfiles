#!/bin/zsh

# ---------------------------------------------------
# 🧠 Install Anki 24.06.3 for compatibility with Butler
# ---------------------------------------------------

# Set required variables
ANKI_VERSION="24.06.3"
ANKI_DMG_URL="https://github.com/ankitects/anki/releases/download/$ANKI_VERSION/anki-$ANKI_VERSION-mac-apple-qt6.dmg"
DMG_NAME="anki-$ANKI_VERSION.dmg"
MOUNT_POINT="/Volumes/Anki"

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
# 1. Open Anki from /Applications
# 2. Sign in to your AnkiWeb account and complete initial sync
# 3. Run the Butler add-on in iCloud Drive in 03 Resources/Software
# 4. Restart Anki to activate the add-on

echo "✅ Anki $ANKI_VERSION installed successfully!"
echo "📌 Follow the post-install instructions in this script to complete setup."