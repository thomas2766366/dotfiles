# Dotfiles

Dotfiles managed with a bare repository.

## Requirements

- git
- zsh
- alacritty
- p10k
- Nerd Font

### Niri specific

- niri
- noctalia
- swaybg
- swaylock
- fuzzel

## Apps or programs with config files

- alacritty
- p10k
- zsh
- nvim
- neofetch
- niri

## Custom scripts

- Random background changer

## Installing the requirements

### Install ZSH & git

Install ZSH and git with the appropriate package manager.
You can also install the preferred apps or programs you want to use.

```bash
sudo apt install zsh git
```

### Set zsh as default

For example with the following command.

```bash
chsh -s $(which zsh)
```

### Install ohmyzsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Zsh Plugins

Install the following zsh plugins.

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
```

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
```

### Nerd Font

Download and install a Nerd Font.

<https://www.nerdfonts.com/>

### Install p10k

```bash
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
```

## Initial setup on a new machine

Setup the repository as a bare repository.

```bash
mkdir ~/dotfiles
git clone --bare https://github.com/thomas2766366/dotfiles.git ~/dotfiles 
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME' 
dotfiles config --local status.showUntrackedFiles no 
dotfiles checkout
```

The command may fail if certain files already exist in your home directory.
You can back them up and delete them or copy the config files manually.

## Backgrounds

The different backgrounds used can be found in the `backgrounds/` folder.

### Random background

You can set a random background within swaybg with the following script.
After you have made the script executable, you can call it to change the background.

```bash
chmod +x ~/backgrounds/change-bg.sh
~/backgrounds/change-bg.sh
```

Currently only works with .jpg files.
The current background will be saved to 'backgounds/current.jpg'.
You can use this file if you have issues with the lockscreen background.
All files with 'current' in the name will be ignored when changing the background.

#### Autostart

The application can be found in [random-wallpaper.desktop](.config/autostart/random-wallpaper.desktop).
Be sure to change the username accordingly.

## For future updates

```bash
dotfiles status 
dotfiles add ~/.zshrc 
dotfiles commit -m "Update zsh config" 
dotfiles push
```
