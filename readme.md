# macos
1. [iTerm2](https://iterm2.com)
2. ```xcode-select --install```
3. [Brew](https://brew.sh):  
   ```/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"```
4. ```brew update && brew upgrade && brew install zsh wget curl git vim tmux make cmake eza gfortran gcc g++ openssl readline sqlite3 xz zlib tcl-tk```
5. ```chsh -s $(which zsh)```
6. kill the terminal app
7. [LaTeX](http://www.tug.org/mactex/)


# ubuntu 
```
sudo apt update
sudo apt upgrade
sudo apt install -y zsh wget curl git vim tmux make cmake exa gcc g++ powerline fonts-powerline gfortran gnome-tweaks gdu build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev gpg
sudo snap refresh
sudo snap install telegram-desktop slack
sudo snap install code --classic
```

```chsh -s $(which zsh)```
> (in the case of problems this might help) `sudo usermod -s /usr/bin/zsh $(whoami)`

**logout**

to apply terminal theme (check profile path):
```
dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < terminal_themes/breeze.dconf
```

## [eza](https://github.com/eza-community/eza#debian-and-ubuntu)
```
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza
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
```
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
  * if you going to copy cfg files then do not initialize mamba/conda right now --- we will do it later
* [pyenv](https://github.com/pyenv/pyenv)
```
curl https://pyenv.run | bash
```
* [tpm](https://github.com/tmux-plugins/tpm)
```
git clone https://github.com/tmux-plugins/tpm ${HOME}/.tmux/plugins/tpm
```
* [neovim](https://github.com/neovim/neovim)
```
sudo snap install nvim --classic
```
* [vscode](https://code.visualstudio.com)
  * [vscode long delete time on KDE](https://jamezrin.name/fix-visual-studio-code-freezing-when-deleting)
* [intel oneapi](https://software.intel.com/content/www/us/en/develop/tools/oneapi/all-toolkits.html)


# copy cfgs
```
cp zshrc ${HOME}/.zshrc
cp profile ${HOME}/.profile
cp zprofile ${HOME}/.zprofile
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
  * or run the following:
  ```
  mkdir -p ${HOME}/.local/share/fonts
  curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
  unzip CascadiaCode.zip -d cascadiacode_tmp
  mv cascadiacode_tmp/*.ttf ${HOME}/.local/share/fonts
  rm -rf cascadiacode_tmp CascadiaCode.zip
  sudo fc-cache -fv
  ```
