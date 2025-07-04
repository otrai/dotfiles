#!/bin/zsh

echo "Setting up git configuration..."

# Create git config folder
mkdir -p ~/.dotfiles/config/git

# Symlink personal Git config to globa Git config path
ln -sf ~/.dotfiles/config/git/gitconfig-personal-macos ~/.gitconfig


echo "Git config set to use: gitconfig-personal-macos"