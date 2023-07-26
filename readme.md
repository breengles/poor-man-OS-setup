# macos
1. [iTerm2](https://iterm2.com)
2. `xcode-select --install`
3. [Brew](https://brew.sh)
4. `brew update`
5. `brew upgrade`
6. `brew install zsh wget curl git vim tmux make cmake exa gfortran gcc g++`
7. `chsh -s $(which zsh)`
8. kill the terminal app
9.  [LaTeX](http://www.tug.org/mactex/)


# ubuntu 
1. `sudo apt update`
2. `sudo apt upgrade`
3. `sudo apt install -y zsh wget curl git vim tmux make cmake exa gcc g++ powerline fonts-powerline gfortran gnome-tweaks texlive-full`
4. `chsh -s $(which zsh)`
  1. (in the case of problems this might help) `sudo usermod -s /usr/bin/zsh $(whoami)`
5. logout
7. to apply terminal theme (check profile path):
```
dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < terminal_themes/breeze.dconf
```
8. snap: 
  1. `sudo snap refresh`
  2. `sudo snap install telegram-desktop slack`
  3. `sudo snap install code --classic`


# [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh#basic-installation)
see [zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH) for `zsh` if you lost.
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/conda-incubator/conda-zsh-completion.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/conda-zsh-completion
git clone --depth=1 https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/autoupdate
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```


# things
* [mambaforge](https://github.com/conda-forge/miniforge#mambaforge)
  * if you going to copy cfg files then do not initialize mamba/conda right now --- we will do it later
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


# fonts
* [CascadiaCode](https://github.com/microsoft/cascadia-code)
* [NerdFont (patched version of fonts, required for tmux theme)](https://github.com/ryanoasis/nerd-fonts)
  * For CascadiaCode version: [archive](https://github.com/ryanoasis/nerd-fonts/releases/latest) / [repo link](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/CascadiaCode)

# copy cfgs
```
cp zshrc ${HOME}/.zshrc
cp aliases ${HOME}/.aliases
cp p10k.zsh ${HOME}/.p10k.zsh
cp tmux.conf ${HOME}/.tmux.conf
cp gitconfig ${HOME}/.gitconfig ; cp gitignore ${HOME}/.gitignore
${HOME}/mambaforge/bin/mamba init zsh
mkdir -p ${HOME}/.config/nvim ; cp vimrc ${HOME}/.config/nvim/init.vim  # for neovim
cp vimrc ${HOME}/.vimrc  # for vim
```
> do not forget to call `:PlugInstall` for (n)vim
> and `<prefix> I` for `tmux`

# mamba base
```
mamba update --all -y
mamba install -y ipython aim jupyterlab numpy pillow opencv
```
