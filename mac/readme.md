* [iTerm2](https://iterm2.com)
* Install X-Code from AppStore
    1. `xcode-select --install`
* [LaTeX](http://www.tug.org/mactex/)
* [Brew](https://brew.sh)
    1. `brew install zsh vim git`
    2. [Antigen](https://github.com/zsh-users/antigen)
    3. [miniconda3](https://conda.io/projects/conda/en/latest/user-guide/install/macos.html)
    4. copy [`zshrc`](zshrc) to home folder, i.e., `cp zshrc ~/.zshrc`
* Conda envs:
    1. `conda env create -f ../environment.yml` --> base
    2. `conda env create -f ml.yml` --> ml
    3. `conda env create -f phys.yml` --> phys
    
