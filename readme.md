# MacOS
```bash
xcode-select --install

# brew https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update && brew upgrade
brew install zsh wget curl git vim neovim tmux make cmake gfortran gcc g++ ranger
brew install --cask keepingyouawake
brew install --cask raycast
brew install --cask iterm2
brew install --cask mactex

brew tap homebrew/cask-fonts
brew install font-caskaydia-cove-nerd-font

wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh
```

## fonts
* [CascadiaCode](https://github.com/microsoft/cascadia-code)
* [NerdFont (patched version of fonts, required for terminal and tmux theme though you can use it for vscode as well)](https://github.com/ryanoasis/nerd-fonts)
  * For CascadiaCode version:
    * [archive](https://github.com/ryanoasis/nerd-fonts/releases/latest)
    * [repo link](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/CascadiaCode)
> for Ubuntu it should be installed with script


# Ubuntu
```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y wget curl git vim tmux make cmake gcc g++ powerline fonts-powerline gfortran gnome-tweaks texlive-full ranger

sudo snap refresh
sudo snap install telegram-desktop slack
sudo snap install code --classic
sudo snap install nvim --classic

# sudo apt install -y restic
# sudo ln -s restic/restic-backup.sh /etc/cron.daily/restic-backup

wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh

mkdir -p "${HOME}/.local/share/fonts/CaskaydiaCoveNerdFont"
curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
unzip CascadiaCode.zip -d cascadiacode_tmp
mv cascadiacode_tmp/*.ttf "${HOME}/.local/share/fonts/CaskaydiaCoveNerdFont"
rm -rf cascadiacode_tmp CascadiaCode.zip
sudo fc-cache -fv

dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < terminal_themes/breeze.dconf
```


# Things
```bash
# omz plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/"zsh-syntax-highlighting
git clone --depth=1 https://github.com/conda-incubator/conda-zsh-completion.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/"conda-zsh-completion
git clone --depth=1 https://github.com/TamCore/autoupdate-oh-my-zsh-plugins "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/autoupdate"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone --depth=1 https://github.com/eza-community/eza.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/eza"

# tmux plugins
git clone https://github.com/tmux-plugins/tpm "${HOME}"/.tmux/plugins/tpm

# rust
curl https://sh.rustup.rs -sSf | sh
cargo install cargo-update tree-sitter-cli ripgrep dua-cli eza zoxide zellij --locked

# ranger
mkdir -p "${HOME}/.config/ranger/plugins"
git clone --depth=1 https://github.com/joouha/ranger_tmux.git "${HOME}/.config/ranger/plugins/ranger_tmux"
git clone --depth=1 https://github.com/alexanderjeurissen/ranger_devicons.git "${HOME}/.config/ranger/plugins/ranger_devicons"

# configs
mkdir -p "${HOME}/.log"  # just creating it as restic backup script relies on it
mkdir -p "${HOME}/.config/ranger"  # this is for ranger file manager; just to be sure it exists
mkdir -p "${HOME}/.config/zellij"  # this is for ranger file manager; just to be sure it exists
cp zshrc "${HOME}/.zshrc"
cp profile "${HOME}/.profile"
cp aliases "${HOME}/.aliases"
cp p10k.zsh "${HOME}/.p10k.zsh"
cp tmux.conf "${HOME}/.tmux.conf"
cp zellij.kdl "${HOME}/.config/zellij/config.kdl
cp gitconfig "${HOME}/.gitconfig" && cp gitignore "${HOME}/.gitignore"
"${HOME}"/miniforge3/bin/mamba init zsh
cp ranger.conf "${HOME}/.config/ranger/rc.conf"
git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git  # yep, it is lazyvim
```


# [intel oneapi](https://software.intel.com/content/www/us/en/develop/tools/oneapi/all-toolkits.html)


# Known issues 
* [vscode long delete time on KDE](https://jamezrin.name/fix-visual-studio-code-freezing-when-deleting)
