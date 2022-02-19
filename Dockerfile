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

RUN \
	pip install --upgrade pip && \
	pip install autobuild

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
