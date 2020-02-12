#
# See: https://wiki.firestormviewer.org/fs_compiling_firestorm_alexivy_debian_9
#
FROM debian:stretch

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN \
	apt-get --yes update && \
	apt-get --yes upgrade

RUN \
	apt-get --yes install --install-recommends make g++ gdb git python2.7 python-pip && \
	apt-get --yes install --install-recommends libgl1-mesa-dev libglu1-mesa-dev libstdc++6 libx11-dev libxinerama-dev libxml2-dev libxrender-dev

# RUN pip install autobuild
RUN pip install "git+https://vcs.firestormviewer.org/autobuild-1.1#egg=autobuild"

# off piste from here:
RUN apt-get --yes install libxrandr-dev libxcursor-dev libxcomposite-dev libxcb-shm0 sudo

RUN apt-get --yes install cmake
#RUN pip install --upgrade cmake

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
