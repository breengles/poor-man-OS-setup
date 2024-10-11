# Poor-man OS setup
Being poor does not mean being useless

## MacOS
```bash
xcode-select --install

# brew https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update && brew upgrade
brew install zsh wget curl git vim neovim tmux make cmake gfortran gcc btop fzf
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
# omz plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
git clone --depth=1 https://github.com/conda-incubator/conda-zsh-completion.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/conda-zsh-completion"
git clone --depth=1 https://github.com/TamCore/autoupdate-oh-my-zsh-plugins "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/autoupdate"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone --depth=1 https://github.com/eza-community/eza.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/eza"

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

# configs
mkdir -p "${HOME}/.config" && cp -r dotconfig/* "${HOME}/.config"
cp dotfiles/.* $HOME
```

## mamba
```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh
```

## fonts
I keep it here just for reference: fonts should be installed with the scripts above
* [CascadiaCode](https://github.com/microsoft/cascadia-code)
* [NerdFont (patched version of fonts, required for terminal and tmux theme though you can use it for vscode as well)](https://github.com/ryanoasis/nerd-fonts)
  * For CascadiaCode version:
    * [archive](https://github.com/ryanoasis/nerd-fonts/releases/latest)
    * [repo link](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/CascadiaCode)

## [intel oneapi](https://software.intel.com/content/www/us/en/develop/tools/oneapi/all-toolkits.html)
