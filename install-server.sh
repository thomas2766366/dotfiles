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
      neovim \
      python3-pip \
      ripgrep \
      fd-find \
      build-essential
    ;;

  arch | manjaro)
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm \
      git \
      zsh \
      curl \
      wget \
      neovim \
      python-pip \
      ripgrep \
      fd \
      base-devel
    ;;

  fedora)
    sudo dnf update -y
    sudo dnf install -y \
      git \
      zsh \
      curl \
      wget \
      neovim \
      python3-pip \
      ripgrep \
      fd-find \
      gcc \
      gcc-c++ \
      make
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

  files_to_backup=(".zshrc" ".p10k.zsh" ".config/nvim")

  for file in "${files_to_backup[@]}"; do
    if [ -e "$HOME/$file" ]; then
      print_info "Backing up $file"
      mkdir -p "$BACKUP_DIR/$(dirname "$file")"
      cp -r "$HOME/$file" "$BACKUP_DIR/$file"
    fi
  done

  if [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    print_info "Existing files backed up to $BACKUP_DIR"
  else
    rmdir "$BACKUP_DIR"
    print_info "No files needed backing up"
  fi
}

# Clone and setup dotfiles for server
install_server_dotfiles() {
  print_info "Installing server dotfiles..."

  # Create temporary directory for selective checkout
  TEMP_REPO=$(mktemp -d)

  # Clone the repository
  git clone https://github.com/thomas2766366/dotfiles.git "$TEMP_REPO"

  # Copy only the server-relevant files
  print_info "Copying zsh configuration..."
  if [ -f "$TEMP_REPO/.zshrc" ]; then
    cp "$TEMP_REPO/.zshrc" "$HOME/.zshrc"
  fi

  if [ -f "$TEMP_REPO/.p10k.zsh" ]; then
    cp "$TEMP_REPO/.p10k.zsh" "$HOME/.p10k.zsh"
  fi

  print_info "Copying neovim configuration..."
  if [ -d "$TEMP_REPO/.config/nvim" ]; then
    mkdir -p "$HOME/.config"
    cp -r "$TEMP_REPO/.config/nvim" "$HOME/.config/"
  fi

  # Clean up temporary repository
  rm -rf "$TEMP_REPO"

  print_info "Server dotfiles installed successfully"
  print_info "Note: dotfiles alias not configured - using direct file copies for server setup"
}

# Alternative: Install dotfiles as bare repository (for full tracking)
install_dotfiles_bare() {
  print_info "Installing dotfiles as bare repository..."

  # Remove existing dotfiles directory if it exists
  if [ -d "$HOME/dotfiles" ]; then
    print_warning "Removing existing dotfiles directory"
    rm -rf "$HOME/dotfiles"
  fi

  # Clone the bare repository
  git clone --bare https://github.com/thomas2766366/dotfiles.git "$HOME/dotfiles"

  # Checkout only the server-relevant files
  if /usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME checkout .zshrc .p10k.zsh .config/nvim 2>&1 | grep -q "error:"; then
    print_warning "Some files would be overwritten. Backing them up first..."
    backup_existing_files
    /usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME checkout -f .zshrc .p10k.zsh .config/nvim 2>/dev/null || true
  else
    /usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME checkout .zshrc .p10k.zsh .config/nvim 2>/dev/null || true
  fi

  # Configure the repository to not show untracked files
  /usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME config --local status.showUntrackedFiles no

  # Add dotfiles alias to .zshrc if not present
  if ! grep -q "alias dotfiles=" "$HOME/.zshrc" 2>/dev/null; then
    echo "alias dotfiles='/usr/bin/git --git-dir=\$HOME/dotfiles/ --work-tree=\$HOME'" >>"$HOME/.zshrc"
  fi

  print_info "Dotfiles installed successfully as bare repository"
}

# Install Nerd Font for better terminal experience (optional for servers)
install_nerd_font() {
  print_info "Installing Nerd Font (for better terminal appearance)..."

  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  if ls "$FONT_DIR"/*Nerd*.ttf 1>/dev/null 2>&1; then
    print_info "Nerd Font already installed"
  else
    print_info "Downloading JetBrainsMono Nerd Font..."
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    TEMP_DIR=$(mktemp -d)

    if wget -q "$FONT_URL" -O "$TEMP_DIR/JetBrainsMono.zip" 2>/dev/null; then
      unzip -q "$TEMP_DIR/JetBrainsMono.zip" -d "$FONT_DIR" 2>/dev/null || true
      rm -rf "$TEMP_DIR"

      # Update font cache
      if command -v fc-cache &>/dev/null; then
        fc-cache -f "$FONT_DIR" 2>/dev/null || true
      fi

      print_info "JetBrainsMono Nerd Font installed"
    else
      print_warning "Failed to download Nerd Font. This is optional for servers."
    fi

    rm -rf "$TEMP_DIR" 2>/dev/null || true
  fi
}

# Main installation function
main() {
  echo ""
  print_info "========================================="
  print_info "  Server Dotfiles Installation Script   "
  print_info "========================================="
  echo ""
  print_info "This will install:"
  echo "  - git, zsh, neovim, and essential tools"
  echo "  - oh-my-zsh with plugins"
  echo "  - powerlevel10k theme"
  echo "  - .zshrc, .p10k.zsh, and nvim config"
  echo ""

  read -p "Continue with installation? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled"
    exit 0
  fi

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

  backup_existing_files
  echo ""

  # Ask user which method to use
  echo "Choose dotfiles installation method:"
  echo "  1) Simple copy (recommended for servers)"
  echo "  2) Bare repository (for full git tracking)"
  read -p "Enter choice (1 or 2): " -n 1 -r
  echo ""

  if [[ $REPLY == "2" ]]; then
    install_dotfiles_bare
  else
    install_server_dotfiles
  fi
  echo ""

  # Optional: Install Nerd Font
  read -p "Install Nerd Font? (recommended if you connect via SSH with a terminal that supports it) (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_nerd_font
    echo ""
  fi

  set_zsh_default
  echo ""

  print_info "========================================="
  print_info "  Installation Complete!                "
  print_info "========================================="
  echo ""
  print_info "Next steps:"
  echo "  1. Log out and log back in (or start a new zsh session)"
  echo "  2. Run 'p10k configure' to set up powerlevel10k"
  echo "  3. Your neovim config (LazyVim) will auto-install plugins on first run"
  echo ""
  print_info "Files installed:"
  echo "  - ~/.zshrc (zsh configuration)"
  echo "  - ~/.p10k.zsh (powerlevel10k theme)"
  echo "  - ~/.config/nvim/ (neovim configuration)"
  echo ""

  if [ -d "$HOME/dotfiles" ]; then
    print_info "Manage dotfiles with:"
    echo "  dotfiles status"
    echo "  dotfiles add <file>"
    echo "  dotfiles commit -m 'message'"
    echo ""
  fi
}

# Run main function
main
