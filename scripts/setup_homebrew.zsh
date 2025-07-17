#!/bin/zsh

# 1. Ask for admin password upfront
if ! sudo -v &>/dev/null; then
  echo "🔐 This script requires sudo privileges."
  exit 1
fi

# 2. Install Xcode Command Line Tools (if not present)
if ! xcode-select -p &>/dev/null; then
  echo "🔧 Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "⏳ Waiting for Xcode Command Line Tools to finish installing..."
  read "REPLY?📦 Press [Enter] once installation is complete to continue..."
else
  echo "✅ Xcode Command Line Tools already installed"
fi

# 3. Install Homebrew (if not present)
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Configure brew for this shell session
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

  # Make sure environment is configured
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# 4. Install packages from Brewfile
DOTFILES_PATH="$HOME/.dotfiles"
BREWFILE="$DOTFILES_PATH/homebrew/Brewfile"

# 4a. Prompt user to sign in if using MAS apps
if [[ -f "$BREWFILE" ]] && grep -q '^mas ' "$BREWFILE"; then
  echo "🛒 App Store apps detected in Brewfile (via mas)."
  echo "💡 Please make sure you're signed in to the App Store *before* continuing."
  echo "⏸️ Press Enter once you're signed in and ready to continue..."
  read -r
fi

if [[ -f "$BREWFILE" ]]; then
  echo "📦 Installing packages from Brewfile..."
  brew bundle --file="$BREWFILE"
  echo "✅ Brewfile installation complete."
else
  echo "❌ Brewfile not found at: $BREWFILE"
  exit 1
fi

# 5. Perform Homebrew maintenance
echo "🔄 Updating Homebrew..."
brew update

echo "⬆️ Upgrading installed packages..."
brew upgrade

echo "🧹 Cleaning up old versions..."
brew cleanup

echo "✅ Homebrew maintenance complete."

: <<'END_BLOCK_COMMENT'

# 6. 🚧 Quarantine removal logic (commented for now)
# These steps require additional work and permissions to be effective.
# See the TODOs for details on possible solutions and security constraints.

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

tools=(
  "displayplacer"
)

for tool in "${tools[@]}"; do
  tool_path="$(which "$tool" 2>/dev/null)"
  if [[ -x "$tool_path" ]]; then
    echo "🔧 Unquarantining: $tool_path"
    sudo xattr -dr com.apple.quarantine "$tool_path"
  else
    echo "⚠️ Tool not found or not executable: $tool"
  fi
done

END_BLOCK_COMMENT

echo "✅ Skipped quarantine removal — see TODOs in script."

# 7. Prompt user to enable VS Code CLI
if ! command -v code &>/dev/null; then
  echo "⚠️ VS Code CLI not found."
  echo "💡 Open VS Code, press ⇧⌘P, and run: Shell Command: Install 'code' command in PATH"
  echo "⏸️ Waiting for you to set up the VS Code CLI..."
  read "REPLY?🔄 Press [Enter] once you've added the 'code' command..."
fi

# 8. Install VS Code extensions from extensions.txt
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