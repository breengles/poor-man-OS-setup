# Before calling `apply.sh`
```bash
brew install zsh  # if macOS
sudo apt install zsh  # if ubuntu
chsh -s $(which zsh)  # if at this step there are problems on ubuntu try this: sudo usermod -s /usr/bin/zsh $(whoami)
```


# After calling `apply.sh`
* do not forget to run `vim -c checkhealth` for vim;
* `<prefix> I` for `tmux`;
* `mamba update --all -y && mamba clean --all -y`;
* `rm ~/.zcompdump*; compinit`;


# fonts
* [CascadiaCode](https://github.com/microsoft/cascadia-code)
* [NerdFont (patched version of fonts, required for tmux theme though you can use it for vscode as well)](https://github.com/ryanoasis/nerd-fonts)
  * For CascadiaCode version:
    * [archive](https://github.com/ryanoasis/nerd-fonts/releases/latest)
    * [repo link](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/CascadiaCode)
> for ubuntu it should be installed already installed via `apply.sh`


# [intel oneapi](https://software.intel.com/content/www/us/en/develop/tools/oneapi/all-toolkits.html)


# Known issues 
* [vscode long delete time on KDE](https://jamezrin.name/fix-visual-studio-code-freezing-when-deleting)
