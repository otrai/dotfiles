#!/bin/zsh

echo "🔐 Apple ID Sign-In Required"
osascript <<EOF
display dialog "To enable iCloud features like Safari, Photos, and Messages:\n\n1. Open System Settings\n2. Click your name at the top (or 'Sign in with your Apple ID')\n3. Sign in and choose what to sync\n\n🧠 Reminder: If you use 1Password, turn OFF iCloud Passwords & Keychain manually." buttons {"OK"}
do shell script "open -a 'System Settings'"
EOF

echo "🔧 Enabling Three-Finger Drag..."

: <<'COMMENT_BLOCK'
───────────────────────────────────────────────────────────────────────────────
⚠️ NOTE: As of macOS Ventura and later, these commands no longer fully enable
"Three-Finger Drag" under:

    System Settings > Accessibility > Pointer Control > Trackpad Options…

macOS now requires manual GUI interaction to enable:
  - "Use trackpad for dragging"
  - "Dragging style" → "Three Finger Drag"

These commands are kept for documentation purposes and legacy reference only.
───────────────────────────────────────────────────────────────────────────────
COMMENT_BLOCK

# Legacy commands (no longer effective)
# defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
# defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2
# defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 2
# sudo defaults write com.apple.universalaccess dragLock -bool false
# sudo defaults write com.apple.universalaccess mouseDriver -int 1

echo "⚠️ Three-Finger Drag must be enabled manually in System Settings"

echo "🔧 Enabling Tap to Click..."

# Built-in trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Per-user setting (current user)
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Login screen (global)
sudo defaults write com.apple.mouse.tapBehavior -int 1

echo "✅ Tap to Click enabled"

echo "🔧 Enabling Secondary Click (two-finger tap)..."

# Enable right-click behavior
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Set right-click style to two-finger tap
# 0 = bottom right corner, 1 = bottom left corner, 2 = two-finger tap
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2

echo "✅ Secondary Click enabled (two-finger tap)"

echo "🔧 Setting swipe gestures to use four fingers..."

# 1 = force 4-finger swipe instead of 3-finger
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1

echo "✅ Swipe gestures set to four fingers"

echo "🔧 Enabling Dock-related gestures and behaviors..."

# Enable swipe up for Mission Control
defaults write com.apple.dock showMissionControlGestureEnabled -int 1

# Enable swipe down for App Exposé
defaults write com.apple.dock showAppExposeGestureEnabled -int 1

# Enable pinch for Launchpad
defaults write com.apple.dock showLaunchpadGestureEnabled -int 1

# Enable spread gesture to show Desktop
defaults write com.apple.dock showDesktopGestureEnabled -int 1

# Automatically hide Dock
defaults write com.apple.dock autohide -bool true

echo "✅ Dock-related gestures and behaviors configured"

# Apply Dock settings
killall Dock

echo "🔧 Disabling Auto-Capitalization..."

# Turn off automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

echo "✅ Auto-Capitalization disabled"

echo "🌘 Configuring UI appearance..."

# Set system appearance to Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Apply UI appearance settings
killall SystemUIServer

echo "✅ UI appearance configured"

echo "🔋 Configuring Power & Security Settings..."

# Disable screen saver (no animation when idle)
defaults -currentHost write com.apple.screensaver idleTime -int 0

# Set display to turn off after 15 minutes (battery or charger)
sudo pmset -a displaysleep 15

# Set system sleep to 45 minutes (battery or charger)
sudo pmset -a sleep 45

# Require password 5 minutes after display turns off
# This gives you a short buffer while keeping your system secure
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 300

echo "✅ Power & Security Settings configured"

echo "🗣️ Dictation Setup"

echo "🧠 Reminder: When prompted with 'Improve Siri & Dictation', click 'Not Now' to avoid sharing audio recordings with Apple."

echo "📍 To enable Dictation:"
echo "1. Open System Settings → Keyboard"
echo "2. Turn on Dictation"
echo "3. Confirm any permissions (e.g. mic access, language)"
echo ""
echo "⏸️ Press Enter when you're done enabling dictation to continue..."
read