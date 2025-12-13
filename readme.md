# Poor-man OS setup

Being poor does not mean being useless

## MacOS

```bash
mkdir -P $HOME/.completions

xcode-select --install

# brew https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update && brew upgrade
brew install zsh wget curl git vim neovim tmux make cmake gfortran gcc btop stow rsync fzf lazygit
brew install --cask kitty keepingyouawake raycast mactex google-chrome visual-studio-code dockey transmission obsidian alt-tab maccy bitwarden font-caskaydia-cove-nerd-font font-monaspace-nerd-font

# some macos settings
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

defaults write -g AppleMiniaturizeOnDoubleClick -bool false
defaults write -g AppleShowAllExtensions -bool true
defaults write -g AppleSpacesSwitchOnActivate -bool false

defaults write -g KeyRepeat -int 2
defaults write -g ApplePressAndHoldEnabled -bool false

defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
```

## Things

```bash
# tmux
git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm

# rust https://github.com/rust-lang/cargo/blob/master/src/doc/src/getting-started/installation.md
curl https://sh.rustup.rs -sSf | sh
cargo install --locked cargo-update tree-sitter-cli ripgrep dua-cli eza zoxide bat yazi-fm yazi-cli fd-find starship pueue

# uv https://docs.astral.sh/uv/getting-started/installation/
curl -LsSf https://astral.sh/uv/install.sh | sh

# vscode/cursor extensions
exts=(
  "anysphere.cpptools"
  "anysphere.cursorpyright"
  "anysphere.remote-containers"
  "anysphere.remote-ssh"
  "charliermarsh.ruff"
  "donjayamanne.githistory"
  "elazarcoh.simply-view-image-for-python-debugging"
  "esbenp.prettier-vscode"
  "gruntfuggly.todo-tree"
  "james-yu.latex-workshop"
  "janisdd.vscode-edit-csv"
  "kevinrose.vsc-python-indent"
  "mhutchie.git-graph"
  "ms-azuretools.vscode-containers"
  "ms-azuretools.vscode-docker"
  "ms-python.debugpy"
  "ms-python.python"
  "ms-toolsai.jupyter"
  "ms-toolsai.jupyter-renderers"
  "ms-toolsai.vscode-jupyter-cell-tags"
  "ms-toolsai.vscode-jupyter-slideshow"
  "pkief.material-icon-theme"
  "randomfractalsinc.vscode-data-preview"
  "redhat.vscode-yaml"
  "streetsidesoftware.code-spell-checker"
  "streetsidesoftware.code-spell-checker-russian"
  "tamasfe.even-better-toml"
  "timonwong.shellcheck"
  "waderyan.gitblame"
)
for ext in "${exts[@]}"; do
  cursor --install-extension "$ext"
done

# from poor-man-OS-setup's root
stow .
```

## Yazi

```bash
ya pkg add yazi-rs/plugins:toggle-pane
ya pkg add yazi-rs/plugins:zoom
```

## Backup

```bash
brew tap garethgeorge/homebrew-backrest-tap
brew install backrest restic
brew services start backrest
```
