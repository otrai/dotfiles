#!/usr/bin/env zsh
# macOS settings bootstrap (Ventura/Sonoma/Sequoia-safe)

set -euo pipefail
pause() { read -r "?⏸️  $1"; }
say()   { echo "$@"; }
is_gui(){ [[ "$(stat -f %Su /dev/console 2>/dev/null || true)" == "$USER" ]]; }

# ---------- GUI guard ----------
if ! is_gui; then
  say "ℹ️  No GUI console user detected; skipping interactive macOS settings."
  exit 0
fi

# ---------- Apple ID + iCloud ----------
say "🔐 Apple ID & iCloud"
osascript <<'OSA' >/dev/null 2>&1 || true
try
  tell application "System Settings" to activate
end try
OSA
say "• Make sure you’re signed in with your Apple ID"
say "• Then in System Settings → [Your Name] → iCloud, ensure iCloud services you want are ON"
pause "Press [Enter] when Apple ID is signed in and iCloud services are set…"

# ---------- Trackpad reminder (no auto-detect) ----------
echo "🖱️ If you use a trackpad, connect/pair it now."
read -r "?   Open Bluetooth settings to pair? (Y/n) " ans
if [[ -z "${ans:-}" || "$ans" =~ ^[Yy]$ ]]; then
  open "x-apple.systempreferences:com.apple.BluetoothSettings" || true
fi
read -r "?⏸️  Press [Enter] once your trackpad is connected (or press now to skip)…"

# ---------- Tap to click ----------
say "🔧 Enabling Tap to Click…"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true || true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1 || true
sudo defaults write com.apple.mouse.tapBehavior -int 1 || true
say "✅ Tap to Click enabled"

# ---------- Secondary click (two-finger) ----------
say "🔧 Enabling Secondary Click (two-finger)…"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true || true
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true || true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true || true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2 || true
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2 || true
say "✅ Secondary Click set to two-finger tap"

# ---------- Three-finger drag (manual) ----------
say "⚠️ Three-Finger Drag must be enabled manually:"
say "   System Settings → Accessibility → Pointer Control → Trackpad Options…"
say "   Enable 'Use trackpad for dragging' → Dragging style: 'Three Finger Drag'"
open "x-apple.systempreferences:com.apple.preference.universalaccess?Seeing_Mouse" || true
pause "Press [Enter] after you’ve set Three-Finger Drag (or skip)…"

# ---------- Dock & Mission Control ----------
say "🔧 Configuring Dock & Mission Control…"
defaults write com.apple.dock showMissionControlGestureEnabled -int 1 || true
defaults write com.apple.dock showAppExposeGestureEnabled -int 1 || true
defaults write com.apple.dock showLaunchpadGestureEnabled -int 1 || true
defaults write com.apple.dock showDesktopGestureEnabled -int 1 || true
defaults write com.apple.dock autohide -bool true || true
defaults write com.apple.dock show-recents -bool false || true
killall Dock >/dev/null 2>&1 || true
say "✅ Dock gestures & behavior updated"

# ---------- Typing ----------
say "🔧 Disabling Auto-Capitalization…"
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false || true
say "✅ Auto-Capitalization disabled"

# ---------- Appearance (Dark Mode) ----------
say "🌘 Enabling Dark Mode…"
osascript -e 'try
  tell application "System Events" to tell appearance preferences to set dark mode to true
end try' >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true
say "✅ Dark Mode enabled"

# ---------- Finder ----------
say "📁 Enabling Finder Path Bar…"
defaults write com.apple.finder ShowPathbar -bool true || true
killall Finder >/dev/null 2>&1 || true
say "✅ Finder Path Bar enabled"

# ---------- Screenshots ----------
say "📸 Making screenshots copy to clipboard…"
defaults write com.apple.screencapture target -string "clipboard" || true
killall SystemUIServer >/dev/null 2>&1 || true
say "✅ Screenshots will copy to clipboard"

# ---------- Power & Security ----------
say "🔋 Power & Security…"
defaults -currentHost write com.apple.screensaver idleTime -int 0 || true
sudo pmset -a displaysleep 15 || true
sudo pmset -a sleep 45 || true
defaults write com.apple.screensaver askForPassword -int 1 || true
defaults write com.apple.screensaver askForPasswordDelay -int 300 || true
say "✅ Power & Security updated"

# ---------- Dictation (manual) ----------
say "🗣️ Dictation: enable manually (CLI options removed by Apple)."
say "   System Settings → Keyboard → Dictation → On"
open "x-apple.systempreferences:com.apple.preference.keyboard?Dictation" || true
pause "Press [Enter] after enabling Dictation (or skip)…"

# ---------- Accessibility: 1Password & ChatGPT ----------
say "🔐 Accessibility for Quick Access apps"
# Launch once so they appear in the list
open -ga "1Password" >/dev/null 2>&1 || true
open -ga "ChatGPT"   >/dev/null 2>&1 || true
sleep 2
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true
say "• In Privacy & Security → Accessibility, enable: 1Password (if shown) and ChatGPT"
say "• If 1Password isn’t listed, quit & relaunch it once, then return to this pane"
pause "Press [Enter] after you’ve adjusted Accessibility (or skip)…"

# ---------- iCloud Keychain & Safari AutoFill (manual) ----------
say "🔐 Avoid duplicate password prompts:"
say "   1) System Settings → [Your Name] → iCloud → Passwords & Keychain → OFF"
say "   2) Safari → Settings → AutoFill:"
say "        ☐ Using information from my contacts"
say "        ☐ User names and passwords"
say "        ☐ Credit cards"
say "        ☐ Other forms"
open -a Safari >/dev/null 2>&1 || true
pause "Press [Enter] when those are set (or skip)…"

# ---------- FYI on random prompts ----------
say "ℹ️ If you see prompts like 'VS Code wants to control System Events' or 'Use head gestures for Siri,'"
say "   they’re optional. It’s safe to choose **Don’t Allow** if you don’t use those features."

# ---------- Done ----------
echo
say "🎉 macOS settings configuration complete!"
say "🔁 You may need to restart macOS or relaunch apps for everything to stick."