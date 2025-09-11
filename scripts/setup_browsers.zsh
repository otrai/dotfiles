#!/usr/bin/env zsh
set -euo pipefail

pause() { read -r "?⏸️  $1"; }
say()   { echo "$@"; }

say "🌐 Setting up 1Password + browsers (terminal prompts only)…"

# --- 1Password desktop & Accessibility (if installed) ---
if [[ -d "/Applications/1Password.app" ]]; then
  say "🔐 Launching 1Password to ensure it registers for Accessibility…"
  open -ga "1Password" || true
  sleep 2
  say "🔐 Grant 1Password Accessibility permission:"
  say "   System Settings → Privacy & Security → Accessibility → enable '1Password'"
  say "   (If it's already enabled, you're good.)"
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || open -a "System Settings"
  pause "Press [Enter] after confirming Accessibility for 1Password…"
else
  say "ℹ️  1Password not installed — skipping Accessibility step."
fi

# --- Safari + 1Password extension ---
say ""
say "🧭 Safari: configure 1Password extension & disable built-in AutoFill"
say "   1) Allow the 1Password extension when prompted (choose 'Always Allow')."
say "   2) Safari → Settings → Websites → 1Password → set 'Allow' for all."
say "   3) Safari → Settings → Extensions → ensure '1Password' is enabled."
say "   4) Safari → Settings → AutoFill → turn OFF everything (you use 1Password)."
open -a Safari "https://github.com/login" || true
pause "Press [Enter] after you’ve adjusted Safari’s permissions/AutoFill…"

# --- Chrome first-run (if installed) ---
if [[ -d "/Applications/Google Chrome.app" ]]; then
  say ""
  say "🌐 Chrome first-run tips:"
  say "   • On first launch, uncheck 'Set Google Chrome as your default browser'."
  say "   • Uncheck usage/crash reporting if you prefer."
  say "   • Sign into Chrome if you want your extensions/settings to sync."
  open -ga "Google Chrome" || true
  pause "Press [Enter] once Chrome’s first-run choices are handled…"
fi

# --- Firefox first-run (if installed) ---
if [[ -d "/Applications/Firefox.app" ]]; then
  say ""
  say "🦊 Firefox first-run tips:"
  say "   • Uncheck 'Make Firefox my default browser'."
  say "   • Turn off telemetry/crash reports if you prefer."
  say "   • Sign into Firefox if you want add-ons to sync."
  open -ga "Firefox" || true
  pause "Press [Enter] once Firefox’s first-run choices are handled…"
fi

say ""
say "✅ Browser setup prompts finished:"
say "   • 1Password Accessibility checked"
say "   • Safari extension allowed + AutoFill disabled"
say "   • Chrome/Firefox first-run handled (if installed)"