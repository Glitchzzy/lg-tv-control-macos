#!/bin/zsh

# Help Message
if [[ " $* " =~ " --help " ]]; then
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --skip-homebrew  Skip Homebrew detection"
  echo "  --skip-mise      Skip Mise detection and installation"
  echo "  --help           Show this help message"
  exit 0
fi

# Check for Homebrew
if [[ ! " $* " =~ " --skip-homebrew " ]]; then
  if ! command -v brew &> /dev/null; then
    echo -e "\033[1;31mHomebrew is not installed. Please install Homebrew and try again.\033[0m"
    exit 1
  fi
fi

# Check and Install Mise
if [[ ! " $* " =~ " --skip-mise " ]]; then
  if ! command -v mise &> /dev/null; then
    echo -e "\033[1;33mMise is not installed. Preparing to install it... CTRL-C to abort.\033[0m"
    sleep 3

    echo -e "\033[32mInstalling Mise...\033[0m"
    brew install mise

    echo 'eval "$(mise activate bash)"' >> ~/.bashrc
    echo 'eval "$(mise activate zsh)"' >> ~/.zshrc

    if [ -f ~/.config/fish/config.fish ]; then
      echo 'eval mise activate fish | source' >> ~/.config/fish/config.fish
    fi
  fi
fi

# Install Hammerspoon
echo -e "\033[32mInstalling Hammerspoon...\033[0m"
brew install -q hammerspoon
HAMMER_CONFIG_PATH=~/.config/hammerspoon
mkdir -p "$HAMMER_CONFIG_PATH/Spoons/LGWebOSRemote"
touch "$HAMMER_CONFIG_PATH/init.lua"
defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"

if ! grep -q 'require "lgtv_init"' "$HAMMER_CONFIG_PATH/init.lua"; then
  echo 'require "lgtv_init"' >> "$HAMMER_CONFIG_PATH/init.lua"
fi
cp ./lgtv_init.lua "$HAMMER_CONFIG_PATH/lgtv_init.lua"

# Download and Install LGWebOSRemote
echo -e "\033[32mDownloading LGWebOSRemote...\033[0m"
LG_REMOTE_PATH=~/.config/hammerspoon/Spoons/
mkdir -p "$LG_REMOTE_PATH"
cd "$LG_REMOTE_PATH"
rm -rf LGWebOSRemote
git clone --quiet https://github.com/Glitchzzy/LGWebOSRemote.git

# Python Setup
echo -e "\033[32mInstalling Python and Dependencies...\033[0m"
cd LGWebOSRemote
mise use python@3.8.18
mise install
mise exec -- python -V

mise exec -- pip install --upgrade pip > /dev/null
mise exec -- pip install setuptools > /dev/null
mise exec -- python setup.py install > /dev/null

# Create Symlink for LGTV Binary
echo -e "\033[32mCreating LGTV Symlink...\033[0m"
LGTVPATH=$(mise exec -- which lgtv)
SCRIPTS_PATH=~/.config/scripts
mkdir -p "$SCRIPTS_PATH"
rm -f "$SCRIPTS_PATH/lgtv"
ln -s "$LGTVPATH" "$SCRIPTS_PATH/lgtv"

"$SCRIPTS_PATH/lgtv" scan ssl

# Completion Message
echo -e "\033[32m\n--------------------------------------------------------------------\033[0m"
echo " Installation Complete!"
echo " You can now use the '$SCRIPTS_PATH/lgtv' command to control your LG TV."
echo -e "\033[32m--------------------------------------------------------------------\n\033[0m"
