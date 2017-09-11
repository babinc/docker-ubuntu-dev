FROM ubuntu:16.04
MAINTAINER Carman Babin

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Update the Apt cache and install basic tools
RUN apt-get update \
  && apt-get install -y \
  software-properties-common \
  openssh-server openssh-client \
  git build-essential curl nano python-dev python-pip python3-dev python3-pip \
  libtool libtool-bin autoconf automake cmake g++ pkg-config unzip libevent-dev libncurses-dev \
  locales sudo ack-grep \
  && apt-get clean

#------------------NODE-----------------------
# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 8.1.4

# Install nvm
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash

# install node and npm
RUN source $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# confirm installation
RUN node -v
RUN npm -v

# install global libs
RUN npm install node-inspect -g
#---------------------------------------------

#-------------------BASH------------------------
# setup bashrc
RUN cd ~ \
  && git clone https://github.com/babinc/.bashrc_conf.git \
  && rm .bashrc \
  && ln -v -s .bashrc_conf/bashrc .bashrc \
  && git clone https://github.com/babinc/.gitconfig_conf.git \
  && ln -s .gitconfig_conf/gitconfig .gitconfig \
  && source ~/.bashrc
#-----------------------------------------------

#------------------TMUX--------------------------
# install TMUX
RUN mkdir ~/src/ \
  && cd ~/src/ \
  && wget https://github.com/tmux/tmux/releases/download/2.2/tmux-2.2.tar.gz \
  && tar -xzvf tmux-2.2.tar.gz \
  && cd tmux-2.2 \
  && ./configure \
  && make \
  && make install

# setup TMUX
RUN cd ~ \
  && locale-gen en_US.UTF-8 \
  && git clone https://github.com/babinc/.tmux_conf.git \
  && ln -v .tmux_conf/tmux.conf .tmux.conf \
  && cd ~/src/ \
  && git clone https://github.com/thewtex/tmux-mem-cpu-load.git \
  && cd tmux-mem-cpu-load/ \
  && cmake . \
  && make \
  && make install
#-----------------------------------------------

#------------------NEOVIM-----------------------
# install neovim
RUN cd ~/src \
  && git clone https://github.com/neovim/neovim.git \
  && cd neovim \
  && git checkout v0.2.0 \
  && make \
  && make install
#------------------------------------------------

#-------------------ADD USER---------------------
ENV USERNAME carman

RUN useradd -m -p $USERNAME $USERNAME && adduser $USERNAME sudo \
  && cp -rf /root/.bashrc_conf/ /home/$USERNAME/ \
  && cp -rf /root/.tmux_conf/ /home/$USERNAME/ \
  && rm /home/$USERNAME/.bashrc \
  && ln -v -s /home/$USERNAME/.bashrc_conf/bashrc /home/$USERNAME/.bashrc \
  && ln -v -s /home/$USERNAME/.tmux_conf/tmux.conf /home/$USERNAME/.tmux.conf \
  && chown -R $USERNAME /home/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

# setup neovim
run mkdir -p ~/.config/nvim \
  && cd ~/.config/nvim \
  && git clone https://github.com/babinc/.vim_conf.git . \
  && curl -flo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# install plugins
RUN nvim +PlugClean! +qall \
  && nvim +PlugInstall! +qall \
  && cd ~/.config/nvim/plugged/YouCompleteMe/ \
  && ./install.py --tern-completer \
  && pip install neovim --user \
  && cd ~/ \
  && git clone https://github.com/babinc/.tern_config.git \
  && ln -s .tern_config/tern-config .tern-config \
  && git clone https://github.com/babinc/.ack_conf.git \
  && ln -s .ack_conf/ackrc .ackrc \
  && git clone https://github.com/babinc/.gitconfig_conf.git \
  && ln -s .gitconfig_conf/gitconfig .gitconfig
#-----------------------------------------------

#-------------------PIP AWS---------------------
# setup pip and aws
RUN mkdir ~/src/ \
  && cd ~/src/ \
  && curl -O https://bootstrap.pypa.io/get-pip.py \
  && python3 get-pip.py --user \
  && touch ~/.bashrc \
  && echo export PATH=~/.local/bin:$PATH >> ~/.bashrc \
  && pip install awscli --upgrade --user
#-----------------------------------------------

#------------------SSH------------------------
USER root
WORKDIR /root/
# setup SSH
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
CMD ["/usr/sbin/sshd", "-D"]
#-----------------------------------------------

#-------------------PORTS-----------------------
EXPOSE 22
EXPOSE 3000
EXPOSE 3001
EXPOSE 8080
