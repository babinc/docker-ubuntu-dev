FROM ubuntu:16.04
MAINTAINER Carman Babin

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Update the Apt cache and install basic tools
RUN apt-get update && apt-get install -y software-properties-common openssh-server openssh-client \
        git build-essential curl tmux nano python-dev python-pip python3-dev python3-pip \
        libtool libtool-bin autoconf automake cmake g++ pkg-config unzip

# Install nvm with node and npm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 8.1.4

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash \
  && source $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default

#setup SSH
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

#download, build, install neovim
RUN mkdir ~/src \
  && cd ~/src \
  && git clone https://github.com/neovim/neovim.git \
  && cd neovim \
  && git checkout v0.2.0 \
  && make \
  && make install

RUN mkdir ~/.config/nvim \
  && cd ~/.config/nvim \
  && git clone https://github.com/babinc/.vim_conf.git . \
  && curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#setup TMUX
RUN git clone https://github.com/babinc/.tmux_conf.git \
  && ln -v .tmux_conf/tmux.conf .tmux.conf

#setup pip and aws
RUN cd ~/src \
  && curl -O https://bootstrap.pypa.io/get-pip.py \
  && python3 get-pip.py --user \
  && touch ~/.bashrc \
  && echo export PATH=~/.local/bin:$PATH >> ~/.bashrc \
  && pip install awscli --upgrade --user

#setup bashrc
RUN cd \
  && git clone https://github.com/babinc/.bashrc_conf.git \
  && rm .bashrc \
  && ln -v -s .bashrc_conf/bashrc .bashrc
#wget https://raw.githubusercontent.com/thestinger/termite/master/termite.terminfo
#source .bashrc
