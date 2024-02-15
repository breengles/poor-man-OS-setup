# macos
```bash
xcode-select --install
# brew https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update && brew upgrade
brew install zsh wget curl git vim neovim tmux make cmake gfortran gcc g++
chsh -s $(which zsh)
# kill the terminal app after changing default shell
```
* [iTerm2](https://iterm2.com)
* [LaTeX](http://www.tug.org/mactex/)


# ubuntu
```bash
# to apply terminal theme (check profile path)
# probably some stuff should be adjusted manually
dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < terminal_themes/breeze.dconf
sudo apt update
sudo apt upgrade
sudo apt install -y zsh wget curl git vim tmux make cmake gcc g++ powerline fonts-powerline gfortran gnome-tweaks gdu restic
sudo snap refresh
sudo snap install telegram-desktop slack
sudo snap install code --classic
sudo snap install nvim --classic
chsh -s $(which zsh) # if at this step there are problems try this: sudo usermod -s /usr/bin/zsh $(whoami)
# latex
sudo apt install -y texlive-full
# logout
# restic daily backups via cron
sudo ln -s restic/restic-backup.sh /etc/cron.daily/restic-backup
```

# [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh#basic-installation)
see [zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH) for `zsh` if you lost.
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/conda-incubator/conda-zsh-completion.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/conda-zsh-completion
git clone --depth=1 https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/autoupdate
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone --depth=1 https://github.com/eza-community/eza.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/eza
```


# things
## [miniforge3](https://github.com/conda-forge/miniforge#miniforge3)
```bash 
# linux
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
```
```bash
# macos
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh
```

## [tpm](https://github.com/tmux-plugins/tpm)
```bash
git clone https://github.com/tmux-plugins/tpm ${HOME}/.tmux/plugins/tpm
```

## [vscode](https://code.visualstudio.com)
[vscode long delete time on KDE](https://jamezrin.name/fix-visual-studio-code-freezing-when-deleting)

## [intel oneapi](https://software.intel.com/content/www/us/en/develop/tools/oneapi/all-toolkits.html)

## [Rust](https://doc.rust-lang.org/cargo/getting-started/installation.html)
```bash
curl https://sh.rustup.rs -sSf | sh
cargo install eza cargo-update tree-sitter-cli ripgrep
cargo install zoxide --locked
```

## [ranger](https://github.com/ranger/ranger/tree/master)
* ubuntu: ```sudo apt install ranger```
* macos: ```brew install ranger```
* other: see [pipx](https://github.com/ranger/ranger/tree/master#installing)

```bash
mkdir -p ${HOME}/.config/ranger/plugins
git clone --depth=1 https://github.com/joouha/ranger_tmux.git ${HOME}/.config/ranger/plugins
git clone --depth=1 https://github.com/alexanderjeurissen/ranger_devicons.git ${HOME}/.config/ranger/plugins
```

for image preview, [ueberzugpp](https://github.com/jstkdng/ueberzugpp).


# configs
```bash
mkdir -p ${HOME}/.log  # just creating it as restic backup script relies on it
mkdir -p ${HOME}/.config/ranger  # this is for ranger file manager; just to be sure it exists
cp zshrc ${HOME}/.zshrc
cp profile ${HOME}/.profile
cp aliases ${HOME}/.aliases
cp p10k.zsh ${HOME}/.p10k.zsh
cp tmux.conf ${HOME}/.tmux.conf
cp gitconfig ${HOME}/.gitconfig && cp gitignore ${HOME}/.gitignore
${HOME}/miniforge3/bin/mamba init zsh
cp ranger.conf ${HOME}/.config/ranger/rc.conf
git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git  # yep, it is lazyvim
```
> do not forget to run `:checkhealth` for nvim;
> and `<prefix> I` for `tmux`;
> and `mamba update --all -y && mamba clean --all -y`;
> and `rm ~/.zcompdump*; compinit`;


# fonts
* [CascadiaCode](https://github.com/microsoft/cascadia-code)
* [NerdFont (patched version of fonts, required for tmux theme though you can use it for vscode as well)](https://github.com/ryanoasis/nerd-fonts)
  * For CascadiaCode version:
    * [archive](https://github.com/ryanoasis/nerd-fonts/releases/latest)
    * [repo link](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/CascadiaCode)

(ubuntu) or run the following for CascadiaCode patched version:
```bash
mkdir -p ${HOME}/.local/share/fonts
curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
unzip CascadiaCode.zip -d cascadiacode_tmp
mv cascadiacode_tmp/*.ttf ${HOME}/.local/share/fonts
rm -rf cascadiacode_tmp CascadiaCode.zip
sudo fc-cache -fv
```


# Archive
## [dropbox ubuntu app fix deprecated key](https://itsfoss.com/key-is-stored-in-legacy-trusted-gpg/)
`sudo apt-key list`
```
sudo apt-key export 5044912E | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/dropbox.gpg
#      recheck that ^^^^^^^^
```

## [syncthing](https://syncthing.net/downloads)
```bash
sudo curl -o /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo apt update && sudo apt install syncthing
cp /usr/share/applications/syncthing-start.desktop ${HOME}/.config/autostart
```
for macos, [download .dmg](https://github.com/syncthing/syncthing-macos/releases)

