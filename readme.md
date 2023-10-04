# macos
1. [iTerm2](https://iterm2.com)
2. ```xcode-select --install```
3. [Brew](https://brew.sh):  
   ```/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"```
4. ```brew update && brew upgrade```
5. ```brew install zsh wget curl git vim neovim tmux make cmake gfortran gcc g++```
6. ```chsh -s $(which zsh)```
7. kill the terminal app
8. [LaTeX](http://www.tug.org/mactex/)


# ubuntu
1. 
```bash
sudo apt update
sudo apt upgrade
sudo apt install -y zsh wget curl git vim tmux make cmake gcc g++ powerline fonts-powerline gfortran gnome-tweaks gdu
sudo snap refresh
sudo snap install telegram-desktop slack
sudo snap install code --classic
sudo snap install nvim --classic
```

2. ```chsh -s $(which zsh)```
> (in the case of problems this might help) `sudo usermod -s /usr/bin/zsh $(whoami)`

3. **logout**

4. to apply terminal theme (check profile path):
```
dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < terminal_themes/breeze.dconf
```

## [dropbox ubuntu app fix deprecated key](https://itsfoss.com/key-is-stored-in-legacy-trusted-gpg/)
`sudo apt-key list`
```
sudo apt-key export 5044912E | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/dropbox.gpg
#      recheck that ^^^^^^^^
```

## latex
```sudo apt install -y texlive-full```


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
* [miniforge3](https://github.com/conda-forge/miniforge#miniforge3)
  * linux: `wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh`
  * macos: `wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh`
* [tpm](https://github.com/tmux-plugins/tpm): ```git clone https://github.com/tmux-plugins/tpm ${HOME}/.tmux/plugins/tpm```
* [vscode](https://code.visualstudio.com)
    * [vscode long delete time on KDE](https://jamezrin.name/fix-visual-studio-code-freezing-when-deleting)
* [intel oneapi](https://software.intel.com/content/www/us/en/develop/tools/oneapi/all-toolkits.html)
* [Rust](https://doc.rust-lang.org/cargo/getting-started/installation.html)
    * ```curl https://sh.rustup.rs -sSf | sh```
    * ```cargo install eza cargo-update```


# configs
```bash
cp zshrc ${HOME}/.zshrc
cp profile ${HOME}/.profile
cp aliases ${HOME}/.aliases
cp p10k.zsh ${HOME}/.p10k.zsh
cp tmux.conf ${HOME}/.tmux.conf
cp gitconfig ${HOME}/.gitconfig ; cp gitignore ${HOME}/.gitignore
${HOME}/miniforge3/bin/mamba init zsh
mkdir -p ${HOME}/.config/nvim ; cp vimrc ${HOME}/.config/nvim/init.vim  # for neovim
cp vimrc ${HOME}/.vimrc  # for vim
```
> do not forget to call `:PlugInstall` for (n)vim
> and `<prefix> I` for `tmux`
> and `mamba update --all -y && mamba clean --all -y`


# fonts
* [CascadiaCode](https://github.com/microsoft/cascadia-code)
* [NerdFont (patched version of fonts, required for tmux theme)](https://github.com/ryanoasis/nerd-fonts)
  * For CascadiaCode version: [archive](https://github.com/ryanoasis/nerd-fonts/releases/latest) / [repo link](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/CascadiaCode)
  * (ubuntu) or run the following:
  ```
  mkdir -p ${HOME}/.local/share/fonts
  curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
  unzip CascadiaCode.zip -d cascadiacode_tmp
  mv cascadiacode_tmp/*.ttf ${HOME}/.local/share/fonts
  rm -rf cascadiacode_tmp CascadiaCode.zip
  sudo fc-cache -fv
  ```
