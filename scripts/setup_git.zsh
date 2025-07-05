#!/bin/zsh

echo "🔧 Setting up Git configuration..."

# Create git config folder
mkdir -p ~/.dotfiles/config/git

# Symlink personal Git config to globa Git config path
ln -sf ~/.dotfiles/config/git/gitconfig-personal-macos ~/.gitconfig

echo "✅ Git config symlink created: ~/.gitconfig → gitconfig-personal-macos"