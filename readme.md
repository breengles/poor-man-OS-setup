# Before calling `apply.sh`
```bash
brew update && brew install zsh  # if macOS
sudo dnf update -y && sudo dnf upgrade -y --refres && sudo apt install zsh  # if fedora

chsh -s $(which zsh)  # if at this step there are problems on ubuntu try this: sudo usermod -s /usr/bin/zsh $(whoami)
```


# After calling `apply.sh`
* do not forget to run `vim -c checkhealth` for vim;
* `<prefix> I` for `tmux`;
* `mamba update --all -y && mamba clean --all -y`;
* `rm ~/.zcompdump*; compinit`;

## [Fedora - NVIDIA](https://rpmfusion.org/Howto/NVIDIA#Installing_the_drivers)
```bash
sudo dnf update -y # and reboot if you are not on the latest kernel
sudo dnf install akmod-nvidia # rhel/centos users can use kmod-nvidia instead
sudo dnf install xorg-x11-drv-nvidia-cuda #optional for cuda/nvdec/nvenc support

# To create the self generated key and certificate:
/usr/sbin/kmodgenca
# To import the key, the command will ask for a password to protect the key
# You will have to enter this password during the special EFI window (MOK...)
mokutil --import /etc/pki/akmods/certs/public_key.der
```


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
