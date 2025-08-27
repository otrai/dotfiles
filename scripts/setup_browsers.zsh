#!/bin/zsh
set -e

# ---------------------------------------------------
# 🌐 1Password + Browsers (Personal)
# ---------------------------------------------------
echo "🌐 Setting up 1Password with Safari, Chrome, and Firefox…"

# (Optional) Make sure 1Password desktop is running so the extension can pair
if [ -d "/Applications/1Password.app" ]; then
  echo "🔐 Launching 1Password…"
  open -a "1Password" || true
  sleep 2
fi

# ---------------------------------------------------
# 🔐 1Password Accessibility permission (needed for Quick Access etc.)
# ---------------------------------------------------
echo "🔐 Opening Accessibility preferences for 1Password…"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || open -a "System Settings"
read "ack_access?⏸️  Press [Enter] after enabling 1Password in Accessibility (or if already enabled)…"
echo "✅ Accessibility enabled for 1Password"

# ---------------------------------------------------
# 🧭 Safari → 1Password permission (Allow on all websites)
# ---------------------------------------------------
# Tip: opening Safari with no URL often triggers the permission prompt from the extension
echo "🧭 Opening Safari to trigger 1Password permission prompt…"
open -a Safari "https://my.1password.com"
sleep 2

osascript <<'EOF'
display dialog "Safari → 1Password permission setup:\n\n1. When prompted, choose 'Always Allow'\n2. Select 'Use on Every Website'\n\nDouble-check (if needed):\n  Safari → Settings → Websites → 1Password\n    • All listed sites: Allow\n    • When visiting other websites: Allow\n\nIf the permission dialog didn’t appear, configure it directly in Settings." buttons {"OK"} default button 1 with icon note
EOF

# Quick verification on GitHub (you should see 1Password offer to fill)
open -a "Safari" "https://github.com/login"
osascript <<'EOF'
display dialog "Verify on GitHub:\n\n• Confirm 1Password offers to fill on the login page\n• If not, try Command+\\ to trigger Autofill\n\nStill no luck? Check:\n  Safari → Settings → Extensions → 1Password (enabled)\n  Safari → Settings → Websites → 1Password → Allow" buttons {"OK"} default button 1 with icon note
EOF

# ---------------------------------------------------
# 🧩 Safari → Disable built-in AutoFill (avoid conflicts)
# ---------------------------------------------------
osascript <<'EOF'
display dialog "Disable Safari AutoFill so 1Password is the only manager:\n\nSafari → Settings → AutoFill\n  • Turn OFF all items:\n    - Using information from contacts\n    - User names and passwords\n    - Credit cards\n    - Other forms" buttons {"OK"} default button 1 with icon note
EOF
echo "✅ Safari AutoFill: review complete"

# ---------------------------------------------------
# 🌐 Chrome → first-run choices
# ---------------------------------------------------
if [ -d "/Applications/Google Chrome.app" ]; then
  open -a "Google Chrome" || true
fi
osascript <<'EOF'
display dialog "Google Chrome first-run setup:\n\n1. Uncheck 'Set Google Chrome as your default browser'\n2. Uncheck 'Help make Google Chrome better' (usage & crash reports)\n\nTip: If you sign into your Google account, extensions (incl. 1Password), bookmarks, and settings can sync automatically." buttons {"OK"} default button 1 with icon note
EOF

# ---------------------------------------------------
# 🦊 Firefox → first-run choices
# ---------------------------------------------------
if [ -d "/Applications/Firefox.app" ]; then
  open -a "Firefox" || true
fi
osascript <<'EOF'
display dialog "Firefox first-run setup:\n\n1. Uncheck 'Make Firefox my default browser'\n2. Uncheck 'Send technical & interaction data to Mozilla'\n3. Uncheck 'Automatically send crash reports'\n\nTip: If you sign into your Firefox account, add-ons (incl. 1Password), bookmarks, and settings can sync automatically." buttons {"OK"} default button 1 with icon note
EOF

# ---------------------------------------------------
# ✅ Done
# ---------------------------------------------------
echo ""
echo "✅ Browser setup prompts shown:"
echo "   • Safari 1Password permission + AutoFill off"
echo "   • Chrome/Firefox first-run privacy/defaults"
echo "🧠 If you use account sync (Google/Firefox), sign in now to pull your extensions."