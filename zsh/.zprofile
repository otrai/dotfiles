# Homebrew setup for Apple Silicon Macs

# Homebrew installation locations
# Give scripts and tools named references to Homebrew's folders.

# Main installation folder.
export HOMEBREW_PREFIX="/opt/homebrew";

# Stores installed packages, organized by name and version.
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";

# Contains Homebrew's own code.
export HOMEBREW_REPOSITORY="/opt/homebrew";


# Shell function search locations
# Let zsh find Homebrew-provided functions, including Tab completions.
# Put this folder at the beginning of the function search list.
# Completion must also be enabled separately to use those completions.
fpath[1,0]="/opt/homebrew/share/zsh/site-functions";


# Command search locations
# Search Homebrew's command folders first.
# Keep the existing $PATH, including folders supplied by macOS
# and installers such as MacTeX.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"


# Manual-page search locations
# Manual pages provide help through commands such as "man ls".
# If MANPATH has a value, preserve it and ensure a leading colon.
# That colon tells the manual reader to also search default locations.
# If MANPATH is unset or empty, leave automatic discovery alone.
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}";


# Info-documentation search locations
# Info is another documentation format used by some command-line tools.
# Add Homebrew's Info folder and preserve any existing locations.
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";


# JetBrains Toolbox terminal launchers.
if [[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]]; then
    path+=("$HOME/Library/Application Support/JetBrains/Toolbox/scripts")
fi

# Keep command search directories unique.
typeset -U path
