# macos
1. [iTerm2](https://iterm2.com)
2. `xcode-select --install`
3. [Brew](https://brew.sh)
4. `brew update`
5. `brew upgrade`
6. `brew install zsh wget curl git vim tmux make cmake`
7. `chsh -s $(which zsh)`
8. kill the terminal app
9.  [LaTeX](http://www.tug.org/mactex/)
10. [optional] `brew install gfortran gcc`


# ubuntu 
1. `sudo apt update`
2. `sudo apt upgrade`
3. `sudo apt install -y zsh wget curl git vim tmux make cmake`
4. `chsh -s $(which zsh)`
   1. (in the case of problems this might help) `sudo usermod -s /usr/bin/zsh $(whoami)`
5. logout
6. (optional) `sudo apt install -y powerline fonts-powerline gfortran gcc g++ texlive-full`


# [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh#basic-installation)
see [zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH) for `zsh` if you lost.
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" ; \
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ; \
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ; \
git clone --depth=1 https://github.com/conda-incubator/conda-zsh-completion.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/conda-zsh-completion ; \
git clone --depth=1 https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/autoupdate
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```


# things
* [mambaforge](https://github.com/conda-forge/miniforge#mambaforge)  
* [tpm](https://github.com/tmux-plugins/tpm)  
```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
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
cp zshrc $HOME/.zshrc ; \
cp p10k.zsh $HOME/.p10k.zsh ; \
cp vimrc $HOME/.vimrc ; \
cp tmux.conf $HOME/.tmux.conf ; \
cp gitconfig $HOME/.gitconfig ; \
cp gitignore $HOME/.gitignore
```
