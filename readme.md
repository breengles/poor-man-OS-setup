# Poor-man OS setup
Being poor does not mean being useless

## terminal
```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh
```

## MacOS
```bash
xcode-select --install

# brew https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update && brew upgrade
brew install zsh wget curl git vim neovim tmux make cmake gfortran gcc g++ btop
brew install --cask keepingyouawake
brew install --cask raycast
brew install --cask mactex
brew install --cask kitty

# nerd font
brew tap homebrew/cask-fonts
brew install font-caskaydia-cove-nerd-font

wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh
```

## Ubuntu
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget curl git vim tmux make cmake gcc g++ powerline fonts-powerline gfortran gnome-tweaks texlive-full

sudo snap refresh
sudo snap install telegram-desktop slack btop
sudo snap install code --classic
sudo snap install nvim --classic


wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i ./google-chrome-stable_current_amd64.deb
```

## Arch
```bash
sudo pacman -S --needed base-devel
sudo pacman -S networkmanager network-manager-applet gcc gcc-fortran git vim zip wget curl tmux telegram-desktop neovim btop nvtop luarocks lua51 fd lazygit

flatpak install flathub com.google.Chrome
flatpak install flathub org.gnome.World.PikaBackup

# install rust beforehand
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

paru visual-studio-code-bin
```

### if using wifi and no networkmanager has been installed
```bash
iwctl
device list

device _name_ set-property Powered on
adapter _adapter_ set-property Powered on

station _name_ scan
station _name_ get-networks
station _name_ connect _SSID_
```

## kitty
```bash
# from https://sw.kovidgoyal.net/kitty/binary/
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# Create symbolic links to add kitty and kitten to PATH (assuming ~/.local/bin is in
# your system-wide PATH)
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
# Place the kitty.desktop file somewhere it can be found by the OS
cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
# If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file
cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
# Update the paths to the kitty and its icon in the kitty desktop file(s)
sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
# Make xdg-terminal-exec (and hence desktop environments that support it use kitty)
echo 'kitty.desktop' > ~/.config/xdg-terminals.list

xdg-mime default org.kde.dolphin.desktop inode/directory

gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty'
```

## font
```bash
mkdir -p "${HOME}/.local/share/fonts/CaskaydiaCoveNerdFont"
curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
unzip CascadiaCode.zip -d CascadiaCode
mv CascadiaCode/*.ttf "${HOME}/.local/share/fonts/CaskaydiaCoveNerdFont"
rm -rf CascadiaCode CascadiaCode.zip

sudo fc-cache -fv
```

## Things
```bash
# omz plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
git clone --depth=1 https://github.com/conda-incubator/conda-zsh-completion.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/conda-zsh-completion"
git clone --depth=1 https://github.com/TamCore/autoupdate-oh-my-zsh-plugins "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/autoupdate"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone --depth=1 https://github.com/eza-community/eza.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/eza"

# tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install --locked cargo-update tree-sitter-cli ripgrep dua-cli eza zoxide bat yazi-fm yazi-cli

# ollama
# fill-in-the-middle
ollama pull starcoder2:3b
# chat
ollama pull llama3.1:8b
ollama pull yi-coder:9b
ollama pull codeqwen:7b-chat
ollama pull deepseek-coder-v2:16b

# configs
mkdir -p "${HOME}/.config" && cp -r dotconfig/* "${HOME}/.config"
cp dotfiles/.* $HOME
```

## mamba
```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh
"${HOME}"/miniforge3/bin/mamba init zsh  # check your shell!
```

## fonts
I keep it here just for reference: fonts should be installed with the scripts above
* [CascadiaCode](https://github.com/microsoft/cascadia-code)
* [NerdFont (patched version of fonts, required for terminal and tmux theme though you can use it for vscode as well)](https://github.com/ryanoasis/nerd-fonts)
  * For CascadiaCode version:
    * [archive](https://github.com/ryanoasis/nerd-fonts/releases/latest)
    * [repo link](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/CascadiaCode)

## [intel oneapi](https://software.intel.com/content/www/us/en/develop/tools/oneapi/all-toolkits.html)

## Known issues 
* [vscode long delete time on KDE](https://jamezrin.name/fix-visual-studio-code-freezing-when-deleting)
