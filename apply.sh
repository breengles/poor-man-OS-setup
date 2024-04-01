#!/usr/bin/env bash


while true; do
    read -p "Did you install zsh already? (y/N) " yn
    yn=${yn:-N}
    case $yn in
        [Yy]* ) echo "Fine. Proceeding to installation."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


if ! [[ "$SHELL" == */zsh ]]; then
    echo "current shell is not zsh: $SHELL"
    exit
fi


OS=$(uname -s)
if [ "$OS" == "Darwin" ]; then
    echo "You are on macOS. Installing macOS stuff..."

    xcode-select --install

    # brew https://brew.sh
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew update && brew upgrade
    brew install zsh wget curl git vim neovim tmux make cmake gfortran gcc g++ ranger
    brew install --cask keepingyouawake
    brew install --cask raycast
    brew install --cask iterm2
    brew install --cask mactex

    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh

elif [ "$OS" == "Linux" ]; then
    echo "You are on Linux. Assuming it is Fedora (the script is only working on it)."

    dnf copr enable faramirza/gdu
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    sudo dnf check-update -y && sudo dnf upgrade -y --refresh
    sudo dnf install -y wget curl git vim tmux make cmake gcc g++ powerline powerline-fonts gfortran gnome-tweaks gdu texlive-scheme-full ranger gnome-tweaks openssl openssl-devel neovim python3-neovim code
    sudo dnf groupupdate core

    # sudo dnf install -y restic
    # sudo ln -s restic/restic-backup.sh /etc/cron.daily/restic-backup

    flatpak install -y flathub org.telegram.desktop com.slack.Slack

    dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < terminal_themes/breeze.dconf

    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh

    mkdir -p "${HOME}/.local/share/fonts/CaskaydiaCoveNerdFont"
    curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
    unzip CascadiaCode.zip -d cascadiacode_tmp
    mv cascadiacode_tmp/*.ttf "${HOME}/.local/share/fonts/CaskaydiaCoveNerdFont"
    rm -rf cascadiacode_tmp CascadiaCode.zip
    sudo fc-cache -fv
else
    echo "This is neither macOS nor Fedora. Exiting."
fi

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
cargo install eza cargo-update tree-sitter-cli ripgrep
cargo install zoxide --locked

# ranger
mkdir -p "${HOME}/.config/ranger/plugins"
git clone --depth=1 https://github.com/joouha/ranger_tmux.git "${HOME}/.config/ranger/plugins/ranger_tmux"
git clone --depth=1 https://github.com/alexanderjeurissen/ranger_devicons.git "${HOME}/.config/ranger/plugins/ranger_devicons"
cp ranger.conf "${HOME}/.config/ranger/rc.conf"

# configs
mkdir -p "${HOME}/log"  # just creating it as restic backup script relies on it
cp zshrc "${HOME}/.zshrc"
cp profile "${HOME}/.profile"
cp aliases "${HOME}/.aliases"
cp p10k.zsh "${HOME}/.p10k.zsh"
cp tmux.conf "${HOME}/.tmux.conf"
cp gitconfig "${HOME}/.gitconfig" && cp gitignore "${HOME}/.gitignore"
"${HOME}"/miniforge3/bin/mamba init zsh
git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git  # yep, it is lazyvim
