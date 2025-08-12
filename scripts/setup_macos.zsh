#!/bin/zsh

# ---------------------------------------------------
# 🔐 Apple ID Sign-In Prompt
# ---------------------------------------------------
echo "🔐 Apple ID Sign-In Required"
osascript <<EOF
display dialog "To enable iCloud features like Safari, Photos, and Messages:\n\n1. Open System Settings\n2. Click your name at the top (or 'Sign in with your Apple ID')\n3. Sign in and choose what to sync\n\n🧠 Reminder: If you use 1Password, turn OFF iCloud Passwords & Keychain manually." buttons {"OK"}
do shell script "open -a 'System Settings'"
EOF

# ---------------------------------------------------
# 🖱️ Trackpad: Three-Finger Drag
# ---------------------------------------------------
: <<'COMMENT_BLOCK'
───────────────────────────────────────────────────────────────────────────────
⚠️ NOTE: As of macOS Ventura and later, these commands no longer fully enable
"Three-Finger Drag" under:

    System Settings > Accessibility > Pointer Control > Trackpad Options…

macOS now requires manual GUI interaction to enable:
  - "Use trackpad for dragging"
  - "Dragging style" → "Three Finger Drag"

These commands are kept for documentation purposes and legacy reference only.
# Legacy commands (no longer effective)
# defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
# defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2
# defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 2
# sudo defaults write com.apple.universalaccess dragLock -bool false
# sudo defaults write com.apple.universalaccess mouseDriver -int 1
COMMENT_BLOCK
───────────────────────────────────────────────────────────────────────────────
echo "🔧 Enabling Three-Finger Drag..."
echo "⚠️ Three-Finger Drag must be enabled manually in System Settings"
echo "   System Settings → Accessibility → Pointer Control → Trackpad Options…"
echo "   Enable 'Use trackpad for dragging' and set style to 'Three Finger Drag'"
read "ack_three_finger?Press [Enter] once Three-Finger Drag is enabled..."

# ---------------------------------------------------
# 🖱️ Trackpad: Tap to Click
# ---------------------------------------------------
echo "🔧 Enabling Tap to Click..."

# Enable tap-to-click on built-in trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Enable tap-to-click for current user
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable tap-to-click on login screen (global)
sudo defaults write com.apple.mouse.tapBehavior -int 1

echo "✅ Tap to Click enabled"

# ---------------------------------------------------
# 🖱️ Trackpad: Secondary Click (Two-Finger Tap)
# ---------------------------------------------------
echo "🔧 Enabling Secondary Click (two-finger tap)..."

# Enable right-click on trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Set right-click to two-finger tap (2 = two-finger tap)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2

echo "✅ Secondary Click enabled (two-finger tap)"

# ---------------------------------------------------
# 🖱️ Trackpad: Swipe Gestures
# ---------------------------------------------------
echo "🔧 Setting swipe gestures to use four fingers..."

# Force 4-finger swipe (instead of 3-finger)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1

echo "✅ Swipe gestures set to four fingers"

# ---------------------------------------------------
# 🧭 Dock & Mission Control Gestures
# ---------------------------------------------------
echo "🔧 Enabling Dock-related gestures and behaviors..."

# Swipe up for Mission Control
defaults write com.apple.dock showMissionControlGestureEnabled -int 1

# Swipe down for App Exposé
defaults write com.apple.dock showAppExposeGestureEnabled -int 1

# Pinch for Launchpad
defaults write com.apple.dock showLaunchpadGestureEnabled -int 1

# Spread to show Desktop
defaults write com.apple.dock showDesktopGestureEnabled -int 1

# Automatically hide the Dock when not in use
defaults write com.apple.dock autohide -bool true

# Hide the 'Recent Applications' section to save Dock space
defaults write com.apple.dock show-recents -bool false

# Apply Dock settings
killall Dock

echo "✅ Dock-related gestures and behaviors configured"

# ---------------------------------------------------
# 📝 Typing Settings
# ---------------------------------------------------
echo "🔧 Disabling Auto-Capitalization..."

# Turn off automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

echo "✅ Auto-Capitalization disabled"

# ---------------------------------------------------
# 🌘 UI Appearance
# ---------------------------------------------------
echo "🌘 Configuring UI appearance..."

# Set system appearance to Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Apply UI appearance settings
killall SystemUIServer

echo "✅ UI appearance configured"

# ---------------------------------------------------
# 📁 Finder Preferences
# ---------------------------------------------------
echo "🔧 Enabling Finder Path Bar..."

# Show full file system path at the bottom of Finder windows
defaults write com.apple.finder ShowPathbar -bool true

# Apply changes
killall Finder

echo "✅ Finder Path Bar enabled (View → Show Path Bar)"

# ---------------------------------------------------
# 📸 Screenshot Settings
# ---------------------------------------------------
echo "📸 Configuring screenshots to copy to clipboard..."

# Always copy screenshots to clipboard instead of saving to desktop
defaults write com.apple.screencapture target clipboard

# Apply changes
killall SystemUIServer

echo "✅ Screenshots will now be copied to clipboard by default"

# ---------------------------------------------------
# 🔋 Power & Security Settings
# ---------------------------------------------------
echo "🔋 Configuring Power & Security Settings..."

# Disable screen saver (0 = never activate)
defaults -currentHost write com.apple.screensaver idleTime -int 0

# Turn off display after 15 minutes (on battery or charger)
sudo pmset -a displaysleep 15

# Sleep the system after 45 minutes (on battery or charger)
sudo pmset -a sleep 45

# Require password after 5 minutes of inactivity
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 300

echo "✅ Power & Security Settings configured"

# ---------------------------------------------------
# 🗣️ Dictation Setup
# ---------------------------------------------------
echo "🗣️ Dictation Setup"

echo "🧠 Reminder: When prompted with 'Improve Siri & Dictation', click 'Not Now' to avoid sharing audio recordings with Apple."

echo "📍 To enable Dictation:"
echo "1. Open System Settings → Keyboard"
echo "2. Turn on Dictation"
echo "3. Confirm any permissions (e.g. mic access, language)"
echo ""
echo "⏸️ Press Enter when you're done enabling dictation to continue..."
read

echo "✅ Dictation setup complete"

# ---------------------------------------------------
# 🔐 1Password Accessibility Permission
# ---------------------------------------------------
echo "🔐 1Password Quick Access requires enabling Accessibility:"
echo "   1. Open System Settings → Privacy & Security → Accessibility"
echo "   2. Click the 🔓 lock in the bottom-left corner and enter your password"
echo "   3. Enable the checkbox next to '1Password'"
echo "   4. Restart 1Password if it was already open"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
read "ack_access?Press [Enter] after enabling 1Password in Accessibility to continue..."
echo "✅ 1Password Quick Access setup complete."

# ---------------------------------------------------
# 🔐 iCloud Keychain & Safari Password Prompts
# ---------------------------------------------------
echo "🔐 Prevent Safari and macOS from prompting to save passwords..."

echo "🧠 Manual Steps:"
echo "   1. Open System Settings → [Your Name] → iCloud → Passwords & Keychain"
echo "   2. Toggle OFF 'Passwords & Keychain'"
echo "   3. Then open Safari → Settings → AutoFill"
echo "      - Turn off 'Usernames and passwords'"
echo "      - Optionally disable other autofill fields"
echo "   4. Restart your Mac to ensure changes persist"

read "ack_keychain?Press [Enter] once you've disabled iCloud Keychain and Safari AutoFill..."

# ---------------------------------------------------
# 🎉 Completion Message
# ---------------------------------------------------
echo ""
echo "🎉 macOS settings configuration complete!"
echo "🔁 You may need to restart your Mac or individual apps (e.g., 1Password, Anki) for all settings to take effect."