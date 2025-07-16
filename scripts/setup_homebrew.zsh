#!/bin/zsh

# Ask for admin password upfront
if ! sudo -v &>/dev/null; then
  echo "🔐 This script requires sudo privileges."
  exit 1
fi

# Step 0: Ensure Xcode Command Line Tools are installed
if ! xcode-select -p &>/dev/null; then
  echo "🔧 Installing Xcode Command Line Tools..."
  xcode-select --install

  echo "⏳ Waiting for Xcode Command Line Tools to finish installing..."
  read "REPLY?📦 Press [Enter] once installation is complete to continue..."
else
  echo "✅ Xcode Command Line Tools already installed"
fi

# Step 1: Install Homebrew if it's not installed
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."

  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Set Homebrew environment for this session
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "❌ Homebrew installation failed or brew not found."
    exit 1
  fi

  echo "✅ Homebrew installed and environment configured."
else
  echo "✅ Homebrew already installed"

  # Ensure environment is still set properly
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Step 2: Install packages from Brewfile
DOTFILES_PATH="$HOME/.dotfiles"
BREWFILE="$DOTFILES_PATH/homebrew/Brewfile"

if [[ -f "$BREWFILE" ]]; then
  echo "📦 Installing packages from Brewfile..."
  brew bundle --file="$BREWFILE"
  echo "✅ Brewfile installation complete."
else
  echo "❌ Brewfile not found at: $BREWFILE"
  exit 1
fi

# Step 3: Update, upgrade, and clean up Homebrew
echo "🔄 Updating Homebrew..."
brew update

echo "⬆️ Upgrading installed packages..."
brew upgrade

echo "🧹 Cleaning up old versions..."
brew cleanup

echo "✅ Homebrew maintenance complete."

: <<'END_BLOCK_COMMENT'

# -----------------------------------------------
# 🚧 Step 4: Remove quarantine flags from GUI apps
# -----------------------------------------------
# TODO: This block attempts to remove quarantine flags recursively
#       using `xattr -dr` on GUI apps like ChatGPT.
#       However, App Sandbox and System Integrity Protection (SIP)
#       prevent modification of deeply nested files in .app bundles.
#       Solution options:
#         - Install casks with `--no-quarantine` instead (preferred)
#         - Drop to root with `sudo` and SIP-disabled system (not ideal)
#         - Try using `spctl --remove` (unreliable for full unquarantine)

apps=(
  "Visual Studio Code"
  "Notion"
  "ChatGPT"
)

for app in "${apps[@]}"; do
  app_path="/Applications/$app.app"
  if [[ -d "$app_path" ]]; then
    echo "🔧 Unquarantining: $app_path"
    sudo xattr -dr com.apple.quarantine "$app_path"
  else
    echo "⚠️ App not found: $app_path"
  fi
done

# -------------------------------------------------
# 🛠️ Step 5: Remove quarantine flags from CLI tools
# -------------------------------------------------
# TODO: This works better than GUI apps but still may fail
#       for tools with internal nested binaries or symlinks.
#       Future option:
#         - Use `--no-quarantine` at install time
#         - Or manually handle sensitive binaries only

tools=(
  "displayplacer"
)

for tool in "${tools[@]}"; do
  tool_path="$(which $tool 2>/dev/null)"
  if [[ -x "$tool_path" ]]; then
    echo "🔧 Unquarantining: $tool_path"
    sudo xattr -dr com.apple.quarantine "$tool_path"
  else
    echo "⚠️ Tool not found or not executable: $tool"
  fi
done

END_BLOCK_COMMENT

echo "✅ Skipped quarantine removal — see TODOs in script."

# Step X: VS Code CLI setup check
if ! command -v code &>/dev/null; then
  echo "⚠️ VS Code CLI not found."
  echo "💡 Open VS Code, press ⇧⌘P, and run: Shell Command: Install 'code' command in PATH"
  echo "⏸️ Waiting for you to set up the VS Code CLI..."
  read "REPLY?🔄 Press [Enter] once you've added the 'code' command..."
fi

# Step X: Install VS Code extensions
# Step X: Install VS Code extensions
VSCODE_EXTENSIONS_FILE="$DOTFILES_PATH/ide/vscode/extensions.txt"

if command -v code &>/dev/null && [[ -f "$VSCODE_EXTENSIONS_FILE" ]]; then
  echo "🧩 Installing VS Code extensions..."
  while IFS= read -r ext; do
    [[ -n "$ext" ]] && code --install-extension "$ext" --force
  done < "$VSCODE_EXTENSIONS_FILE"
  echo "✅ VS Code extensions installation complete."
else
  echo "⚠️ VS Code CLI still not found or extensions list missing."
fi