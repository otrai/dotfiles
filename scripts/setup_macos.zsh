#!/bin/zsh

echo "🔐 Apple ID Sign-In Required"
osascript <<EOF
display dialog "To enable iCloud features like Safari, Photos, and Messages:\n\n1. Open System Settings\n2. Click your name at the top (or 'Sign in with your Apple ID')\n3. Sign in and choose what to sync\n\n🧠 Reminder: If you use 1Password, turn OFF iCloud Passwords & Keychain manually." buttons {"OK"}
do shell script "open -a 'System Settings'"
EOF

echo "🧠 Reminder: Disable iCloud Passwords & Keychain manually if you use 1Password instead"

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

# Enable Three-Finger Drag (legacy settings — no longer effective)
# defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
# defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2
# defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 2

# Accessibility system preferences (ignored by Ventura+)
# sudo defaults write com.apple.universalaccess dragLock -bool false  # Normal drag behavior (no drag lock)
# sudo defaults write com.apple.universalaccess mouseDriver -int 1

echo "⚠️ Three-Finger Drag must be enabled manually in System Settings"

echo "🔧 Enabling Tap to Click..."

# Enable tap to click for the built-in trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Enable tap to click for current user (affects new trackpads too)
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable tap to click for login screen
sudo defaults write com.apple.mouse.tapBehavior -int 1

echo "✅ Tap to Click enabled"

echo "🔧 Enabling Secondary Click (two-finger tap)..."

# Enable right-click behavior
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

# Set style to two-finger tap (0 = bottom right, 1 = bottom left, 2 = two-finger tap)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2

echo "✅ Secondary Click enabled (two-finger tap)"

echo "🔧 Setting swipe gestures to use four fingers..."

# Force swipe gestures (Mission Control, App Exposé, full-screen apps) to use 4 fingers
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1

echo "✅ Swipe gestures set to four fingers"

echo "🔧 Enabling Mission Control Gesture..."

# Enable Mission Control gesture (swipe up)
defaults write com.apple.dock showMissionControlGestureEnabled -int 1

echo "✅ Mission Control Gesture enabled"

echo "🔧 Enabling App Exposé Gesture..."

# Enable App Exposé gesture (swipe down)
defaults write com.apple.dock showAppExposeGestureEnabled -int 1

echo "✅ App Exposé Gesture enabled"

echo "🔧 Enabling Launchpad Gesture (pinch)..."

# Enable pinch gesture to open Launchpad
defaults write com.apple.dock showLaunchpadGestureEnabled -int 1

echo "✅ Launchpad Gesture enabled"

echo "🔧 Enabling Show Desktop Gesture (spread)..."

# Enable spread gesture to show desktop
defaults write com.apple.dock showDesktopGestureEnabled -int 1

echo "✅ Show Desktop Gesture enabled"

# Apply Dock-related gesture changes
killall Dock

echo "🌘 Configuring UI appearance..."

# Set system appearance to Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Restart UI to apply settings
killall SystemUIServer

echo "✅ UI appearance configured"