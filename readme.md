# Poor-man OS setup
Being poor does not mean being useless

## MacOS
```bash
xcode-select --install

# brew https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update && brew upgrade
brew install zsh wget curl git vim neovim tmux make cmake gfortran gcc btop stow
brew install --cask kitty
brew install --cask keepingyouawake
brew install --cask raycast
brew install --cask mactex
brew install --cask nikitabobko/tap/aerospace

# nerd font
brew install font-caskaydia-cove-nerd-font
```

## Things
```bash
# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install --locked cargo-update tree-sitter-cli ripgrep dua-cli eza zoxide bat yazi-fm yazi-cli

# ollama
ollama pull starcoder2:3b
ollama pull llama3.1:8b
ollama pull yi-coder:9b
ollama pull codeqwen:7b-chat
ollama pull deepseek-coder-v2:16b

# mamba
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh

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
