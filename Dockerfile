#
# See: https://wiki.firestormviewer.org/fs_compiling_firestorm_linux_ubuntu18
#
ARG FD_UBUNTU_VERSION

FROM ubuntu:$FD_UBUNTU_VERSION

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN \
	apt-get --yes update && \
	apt-get --yes upgrade

RUN apt --yes install --install-recommends \
	libgl1-mesa-dev libglu1-mesa-dev libpulse-dev build-essential python-pip git \
	python3-pip libfontconfig1-dev libfreetype6-dev \
	libssl-dev \
	libxcb-shm0 \
	libxcb-shm0-dev \
	libxcomposite-dev \
	libxcursor-dev \
	libxinerama-dev \
	libxml2-dev \
	libxrandr-dev \
	libxrender-dev \
	gdb \
	openssl1.0 \
	sudo \
	wget


# autobuild needs python >=3.7 (3.6 is shipped with Ubuntu 18.04)
RUN \
	apt install -y python3.8 && \
	update-alternatives --install /usr/bin/python python /usr/bin/python3.8 9 && \
	update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 9 && \
	pip3 install --upgrade pip && \
	pip3 install git+https://bitbucket.org/lindenlab/autobuild.git#egg=autobuild

RUN \
	cd /tmp && \
	wget https://github.com/Kitware/CMake/releases/download/v3.18.0/cmake-3.18.0.tar.gz && \
	tar xvf cmake-3.18.0.tar.gz && \
	cd cmake-3.18.0 && \
	./bootstrap --prefix=/usr && make -j 4 && make install

RUN \
	apt-get install -y systemd \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
	rm -f /lib/systemd/system/multi-user.target.wants/* \
	/etc/systemd/system/*.wants/* \
	/lib/systemd/system/local-fs.target.wants/* \
	/lib/systemd/system/sockets.target.wants/*udev* \
	/lib/systemd/system/sockets.target.wants/*initctl* \
	/lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
	/lib/systemd/system/systemd-update-utmp*

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/lib/systemd/systemd"]
