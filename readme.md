# Poor-man OS setup
Being poor does not mean being useless

## MacOS
```bash
mkdir -P $HOME/.completions

xcode-select --install

# brew https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update && brew upgrade
brew install zsh wget curl git vim neovim tmux make cmake gfortran gcc btop stow uv
brew install --cask kitty
brew install --cask keepingyouawake
brew install --cask raycast
brew install --cask mactex
brew install --cask nikitabobko/tap/aerospace
brew install --cask google-chrome
brew install --cask visual-studio-code
brew install --cask dockey
brew install --cask transmission

# nerd font
brew install font-caskaydia-cove-nerd-font

# https://nikitabobko.github.io/AeroSpace/goodness#disable-open-animations
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
```

## Things
```bash
# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
$HOME/.fzf/install --all

# tmux
git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install --locked cargo-update tree-sitter-cli ripgrep dua-cli eza zoxide bat yazi-fm yazi-cli zellij

# zellij plugins
mkdir -p $HOME/zellij-plugins
wget -P $HOME/zellij-plugins https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm

# ollama
ollama pull qwen2.5-coder:7b
ollama pull qwen2.5-coder:32b
ollama pull starcoder2:3b

ollama pull llama3.2:3b
ollama pull llama3.2-vision:11b


# mamba
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh

# uv
uv tool install --python python3.12 aider-chat

# from poor-man-OS-setup's root
stow .
```

## fonts
I keep it here just for reference: fonts should be installed with the scripts above
* [CascadiaCode](https://github.com/microsoft/cascadia-code)
* [NerdFont (patched version of fonts, required for terminal and tmux theme though you can use it for vscode as well)](https://github.com/ryanoasis/nerd-fonts)
  * For CascadiaCode version:
    * [archive](https://github.com/ryanoasis/nerd-fonts/releases/latest)
    * [repo link](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/CascadiaCode)

## [intel oneapi](https://software.intel.com/content/www/us/en/develop/tools/oneapi/all-toolkits.html)
