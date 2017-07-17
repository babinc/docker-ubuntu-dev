FROM ubuntu:16.04
MAINTAINER Carman Babin

# Update the Apt cache and install basic tools
RUN apt-get update && apt-get install -y software-properties-common openssh-server openssh-client \
	git build-essential curl tmux nano python-dev python-pip python3-dev python3-pip \
	libtool libtool-bin autoconf automake cmake g++ pkg-config unzip

# Install nvm with node and npm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
RUN source ~/.bashrc
RUN nvm install v8.1.4

#setup SSH
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

#setup TMUX
#git clone https://github.com/babinc/.tmux_conf.git
#ln -v .tmux_conf/tmux.conf .tmux.conf

#download, build, install neovim
RUN mkdir ~/src && cd ~/src
RUN git clone https://github.com/neovim/neovim.git
RUN git checkout v0.2.0
RUN make && make install
RUN mkdir ~/.config/nvim && cd ~/.config/nvim
RUN git clone https://github.com/babinc/.vim_conf.git .
RUN curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#setup pip and aws
RUN cd ~/src && curl -O https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py --user
RUN cat export PATH=~/.local/bin:$PATH > ~/.bashrc
RUN pip install awscli --upgrade --user

#setup bashrc
#git clone https://github.com/babinc/.bashrc_conf.git
#rm .bashrc
#ln -v -s .bashrc_conf/bashrc .bashrc
#wget https://raw.githubusercontent.com/thestinger/termite/master/termite.terminfo
#source .bashrc
