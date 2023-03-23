Ubuntu specifics
================

# Common
```
sudo apt update
sudo apt install -y gfortran gcc g++ texlive-full wget curl git vim tmux cmake
```

# Docker
```
sudo apt update

sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io
```

Permission for docker:
```
sudo groupadd docker

sudo usermod -aG docker $USER

newgrp docker
```


# [VSCode long delete time on KDE](https://jamezrin.name/fix-visual-studio-code-freezing-when-deleting)
