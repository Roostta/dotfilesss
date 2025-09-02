#!/usr/bin/env bash
set -euo pipefail

# =========
# SETTINGS
# =========
DOTFILES_REPO="https://github.com/cristianpb/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# =========
# FUNCTIONS
# =========
install_packages() {
  echo "[*] Installing dependencies..."
  if command -v apt &>/dev/null; then
    sudo apt update
    sudo apt install -y \
      git curl wget zsh neovim tmux stow \
      i3 polybar rofi feh picom \
      build-essential cmake pkg-config \
      python3 python3-pip \
      fonts-font-awesome unzip
  elif command -v pacman &>/dev/null; then
    sudo pacman -Syu --noconfirm \
      git curl wget zsh neovim tmux stow \
      i3-wm polybar rofi feh picom \
      base-devel cmake pkgconf unzip \
      python python-pip \
      ttf-font-awesome
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y \
      git curl wget zsh neovim tmux stow \
      i3 polybar rofi feh picom \
      make automake gcc gcc-c++ kernel-devel cmake unzip \
      python3 python3-pip \
      fontawesome-fonts
  else
    echo "Unsupported package manager. Install dependencies manually."
    exit 1
  fi
}

install_fonts() {
  echo "[*] Installing Nerd Fonts..."
  mkdir -p "$HOME/.local/share/fonts"
  cd "$HOME/.local/share/fonts"
  # Example: Hack Nerd Font
  curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
  unzip -o Hack.zip -d Hack
  rm Hack.zip
  fc-cache -fv
}

clone_repo() {
  if [[ -d "$DOTFILES_DIR" ]]; then
    echo "[*] Dotfiles already exist, pulling latest..."
    git -C "$DOTFILES_DIR" pull
  else
    echo "[*] Cloning dotfiles..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}

setup_dotfiles() {
  echo "[*] Setting up dotfiles with stow..."
  cd "$DOTFILES_DIR"
  stow */
}

setup_polybar() {
  echo "[*] Setting up Polybar as default..."
  
  # Copy polybar configs
  mkdir -p "$HOME/.config/polybar"
  cp -r "$DOTFILES_DIR/config/polybar/"* "$HOME/.config/polybar/" || true

  # Patch i3 config
  I3_CONFIG="$HOME/.config/i3/config"
  if [[ -f "$I3_CONFIG" ]]; then
    # Comment out any bar { } block for i3bar
    sed -i '/^bar {/,/^}/ s/^/#/' "$I3_CONFIG"
    # Ensure polybar is autostarted
    if ! grep -q "polybar main" "$I3_CONFIG"; then
      echo -e '\n# Start polybar instead of i3bar\nexec_always --no-startup-id polybar main' >> "$I3_CONFIG"
    fi
  fi
}

change_shell() {
  if [[ "$SHELL" != "$(which zsh)" ]]; then
    echo "[*] Changing default shell to zsh..."
    chsh -s "$(which zsh)"
  fi
}

# =========
# MAIN
# =========
install_packages
install_fonts
clone_repo
setup_dotfiles
setup_polybar
change_shell

echo "[✔] Installation complete!"
echo "👉 Logout/restart i3 to see changes."
