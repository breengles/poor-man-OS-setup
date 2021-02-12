# zsh_config

```
sudo apt update
sudo apt install -y python3 python3-pip nvidia-cuda-toolkit \
gfortran gcc g++ texlive-full \ 
wget curl git vim tmux cmake \
xz-utils tk-dev libffi-dev liblzma-dev python-openssl apt-transport-https \
ca-certificates gnupg-agent software-properties-common
```

* ZSH
1. `sudo apt install zsh`
2. `sudo usermod -s /usr/bin/zsh $(whoami)`
3. logout
4. (optional) `sudo apt install powerline fonts-powerline`
5. [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`


* [Pyenv](https://github.com/pyenv/pyenv-installer)
```
sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev python-openssl git

curl https://pyenv.run | bash
```

* [PyTorch](https://pytorch.org/get-started/locally/)

* [Sporify](https://www.spotify.com/ru-ru/download/linux/)

* [Docker](https://docs.docker.com/engine/install/ubuntu/)
```
sudo apt update

sudo apt install \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"

sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io
```

Permission:
```
sudo groupadd docker

sudo usermod -aG docker $USER

newgrp docker
```

