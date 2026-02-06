#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored messages
print_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Detect distribution
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
  else
    print_error "Cannot detect distribution"
    exit 1
  fi
}

# Install packages based on distribution
install_packages() {
  print_info "Installing packages for $DISTRO..."

  case $DISTRO in
  ubuntu | debian)
    sudo apt update
    sudo apt install -y \
      git \
      zsh \
      curl \
      wget \
      alacritty \
      neovim \
      neofetch \
      swaybg \
      swaylock \
      fuzzel \
      fonts-powerline

    # Try to install niri from source or snap if not available
    if ! command -v niri &>/dev/null; then
      print_warning "niri not available in apt, you may need to install it manually"
      print_info "Visit: https://github.com/YaLTeR/niri"
    fi
    ;;

  arch | manjaro)
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm \
      git \
      zsh \
      curl \
      wget \
      alacritty \
      neovim \
      neofetch \
      swaybg \
      swaylock \
      fuzzel \
      ttf-nerd-fonts-symbols \
      ttf-nerd-fonts-symbols-mono

    # Install niri from AUR if available
    if command -v yay &>/dev/null; then
      yay -S --noconfirm niri || print_warning "Failed to install niri, install manually if needed"
    elif command -v paru &>/dev/null; then
      paru -S --noconfirm niri || print_warning "Failed to install niri, install manually if needed"
    else
      print_warning "No AUR helper found. Install yay or paru to install niri"
    fi
    ;;

  fedora)
    sudo dnf update -y
    sudo dnf install -y \
      git \
      zsh \
      curl \
      wget \
      alacritty \
      neovim \
      neofetch \
      swaybg \
      swaylock \
      fuzzel \
      powerline-fonts \
      fontawesome-fonts

    # Try to install niri
    if ! command -v niri &>/dev/null; then
      print_warning "niri not available in dnf, you may need to install it manually"
      print_info "Visit: https://github.com/YaLTeR/niri"
    fi
    ;;

  *)
    print_error "Unsupported distribution: $DISTRO"
    exit 1
    ;;
  esac

  print_info "Packages installed successfully"
}

# Set zsh as default shell
set_zsh_default() {
  print_info "Setting zsh as default shell..."

  if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    print_info "Default shell set to zsh. Please log out and log back in for changes to take effect."
  else
    print_info "zsh is already the default shell"
  fi
}

# Install oh-my-zsh
install_ohmyzsh() {
  print_info "Installing oh-my-zsh..."

  if [ -d "$HOME/.oh-my-zsh" ]; then
    print_warning "oh-my-zsh is already installed"
  else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_info "oh-my-zsh installed successfully"
  fi
}

# Install zsh plugins
install_zsh_plugins() {
  print_info "Installing zsh plugins..."

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # Install zsh-autosuggestions
  if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    print_warning "zsh-autosuggestions already installed"
  else
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    print_info "zsh-autosuggestions installed"
  fi

  # Install zsh-syntax-highlighting
  if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    print_warning "zsh-syntax-highlighting already installed"
  else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    print_info "zsh-syntax-highlighting installed"
  fi
}

# Install powerlevel10k
install_p10k() {
  print_info "Installing powerlevel10k..."

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    print_warning "powerlevel10k already installed"
  else
    git clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    print_info "powerlevel10k installed"
  fi
}

# Backup existing dotfiles
backup_existing_files() {
  print_info "Backing up existing dotfiles..."

  BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$BACKUP_DIR"

  files_to_backup=(".zshrc" ".p10k.zsh" ".config/alacritty" ".config/nvim" ".config/neofetch" ".config/niri" ".config/swaylock" ".config/autostart")

  for file in "${files_to_backup[@]}"; do
    if [ -e "$HOME/$file" ]; then
      print_info "Backing up $file"
      mkdir -p "$BACKUP_DIR/$(dirname "$file")"
      mv "$HOME/$file" "$BACKUP_DIR/$file"
    fi
  done

  if [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    print_info "Existing files backed up to $BACKUP_DIR"
  else
    rmdir "$BACKUP_DIR"
    print_info "No files needed backing up"
  fi
}

# Clone dotfiles as bare repository
install_dotfiles() {
  print_info "Installing dotfiles..."

  # Remove existing dotfiles directory if it exists
  if [ -d "$HOME/dotfiles" ]; then
    print_warning "Removing existing dotfiles directory"
    rm -rf "$HOME/dotfiles"
  fi

  # Clone the bare repository
  git clone --bare https://github.com/thomas2766366/dotfiles.git "$HOME/dotfiles"

  # Define dotfiles alias temporarily
  alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'

  # Checkout the dotfiles
  if /usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME checkout 2>&1 | grep -q "error: The following untracked working tree files would be overwritten"; then
    print_warning "Some files would be overwritten. Backing them up first..."
    backup_existing_files
    /usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME checkout
  else
    /usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME checkout
  fi

  # Configure the repository to not show untracked files
  /usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME config --local status.showUntrackedFiles no

  print_info "Dotfiles installed successfully"
}

# Make background script executable
setup_backgrounds() {
  print_info "Setting up background scripts..."

  if [ -f "$HOME/backgrounds/change-bg.sh" ]; then
    chmod +x "$HOME/backgrounds/change-bg.sh"
    print_info "Background script is now executable"
  else
    print_warning "Background script not found at ~/backgrounds/change-bg.sh"
  fi
}

# Install noctalia (if not already installed)
install_noctalia() {
  print_info "Checking for noctalia..."

  if command -v noctalia &>/dev/null; then
    print_info "noctalia is already installed"
  else
    print_warning "noctalia not found. You may need to install it manually."
    print_info "Visit: https://github.com/SIMULATAN/noctalia"
  fi
}

# Download and install a Nerd Font
install_nerd_font() {
  print_info "Checking for Nerd Fonts..."

  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  if ls "$FONT_DIR"/*Nerd*.ttf 1>/dev/null 2>&1; then
    print_info "Nerd Font already installed"
  else
    print_info "Downloading JetBrainsMono Nerd Font..."
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    TEMP_DIR=$(mktemp -d)

    wget -q "$FONT_URL" -O "$TEMP_DIR/JetBrainsMono.zip"
    unzip -q "$TEMP_DIR/JetBrainsMono.zip" -d "$FONT_DIR"
    rm -rf "$TEMP_DIR"

    # Update font cache
    if command -v fc-cache &>/dev/null; then
      fc-cache -f "$FONT_DIR"
    fi

    print_info "JetBrainsMono Nerd Font installed"
  fi
}

# Main installation function
main() {
  print_info "Starting dotfiles installation..."
  echo ""

  detect_distro
  print_info "Detected distribution: $DISTRO"
  echo ""

  install_packages
  echo ""

  install_ohmyzsh
  echo ""

  install_zsh_plugins
  echo ""

  install_p10k
  echo ""

  install_nerd_font
  echo ""

  install_dotfiles
  echo ""

  setup_backgrounds
  echo ""

  install_noctalia
  echo ""

  set_zsh_default
  echo ""

  print_info "Installation complete!"
  echo ""
  print_info "Please note:"
  echo "  1. Log out and log back in for shell changes to take effect"
  echo "  2. Run 'p10k configure' to configure powerlevel10k after logging in"
  echo "  3. You can manage your dotfiles with: alias dotfiles='/usr/bin/git --git-dir=\$HOME/dotfiles/ --work-tree=\$HOME'"
  echo "  4. Update username in ~/.config/autostart/random-wallpaper.desktop if needed"
  echo "  5. Some packages like niri and noctalia may need manual installation"
  echo ""
}

# Run main function
main
