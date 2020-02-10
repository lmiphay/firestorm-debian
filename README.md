# firestorm-debian

A docker build environment for firestorm based on debian:stretch.

This builds:

1. a debian 9 stretch container with the firestorm build dependencies installed.
2. makes firestorm build from the head of: phoenix-firestorm

# Host Requirements

1. working docker installation
2. gnu make
3. approximately 20G of space for the build

# Settings

These settings can be overriden from the environment.

## Settings related to the host

+ FD_DEBIAN_VERSION is the version of the base debian image [default: stretch ]
+ FD_FIRESTORM_IMAGE is the name of the docker image built with firestorm dependencies added [default: firestorm/debian:stretch ]
+ FD_FIRESTORM_CONTAINER is the name of the container to be built [default: firestorm-debian-stretch ]
+ FD_HOST_REPOS_DIR is the location of the repo's on the host system [default: /cache/src/firestorm ]

## Settings relevant inside the container

+ FD_CONTAINER_REPOS_DIR is the mounted location of the repo's inside in the container [default: /local/src/firestorm ]
+ FD_CONTAINER_USER_GROUP is the user:group that should map to the user on host which owns the repos [default: user:group running the build]

## Settings relevant to the build

+ FD_AUTOBUILD_BUILD_ID is the value passed to the AUTOBUILD_VARIABLES_ID autobuild variable [default: "{HOSTNAME}-timestamp"]

# Building

## Check settings

Examine and fix (if necessary) the configured settings:
```
$ make settings
FD_AUTOBUILD_BUILD_ID=nur-2019-11-19-21:11:34
FD_CONTAINER_REPOS_DIR=/local/src/firestorm
FD_CONTAINER_USER_GROUP=lmiphay:lmiphay
FD_DEBIAN_VERSION=stretch
FD_FIRESTORM_CONTAINER=firestorm-debian-stretch
FD_FIRESTORM_IMAGE=firestorm/debian:stretch
FD_HOST_REPOS_DIR=/cache/src/firestorm
$
```

# Create the image

This builds a debian image with the firestorm build dependencies installed:
```
$ make image
docker build --progress=plain --tag firestorm/debian:stretch .
Sending build context to Docker daemon  138.2kB
Step 1/14 : FROM debian:stretch
 ---> 4f5edfdf153f
Step 2/14 : ENV container docker
 ---> Running in ad19af90246c
Removing intermediate container ad19af90246c
 ---> 58bf92a7c21b
Step 3/14 : ENV LC_ALL C
 ---> Running in 9056960b7de3
Removing intermediate container 9056960b7de3
 ---> 0d4794a99e85
Step 4/14 : ENV DEBIAN_FRONTEND noninteractive
 ---> Running in 84d8178bb03d
Removing intermediate container 84d8178bb03d
 ---> ba28be20c448
Step 5/14 : RUN 	apt-get update && 	apt-get upgrade
 ---> Running in e3b6c2905468

...

Step 11/14 : RUN 	rm -f /lib/systemd/system/multi-user.target.wants/* 	/etc/systemd/system/*.wants/* 	/lib/systemd/system/local-fs.target.wants/* 	/lib/systemd/system/sockets.target.wants/*udev* 	/lib/systemd/system/sockets.target.wants/*initctl* 	/lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* 	/lib/systemd/system/systemd-update-utmp*
 ---> Running in 4e5005ad3639
Removing intermediate container 4e5005ad3639
 ---> c3128c7f2d2d
Step 12/14 : COPY cp-user clone-or-update /usr/local/bin/
 ---> 75c6f7a6d193
Step 13/14 : VOLUME [ "/sys/fs/cgroup" ]
 ---> Running in 9dc6d4205321
Removing intermediate container 9dc6d4205321
 ---> 3265b20a3a71
Step 14/14 : CMD ["/lib/systemd/systemd"]
 ---> Running in 2ede430e7be0
Removing intermediate container 2ede430e7be0
 ---> c73d846b6738
Successfully built c73d846b6738
Successfully tagged firestorm/debian:stretch
firestorm/debian      stretch             c73d846b6738        About a minute ago   829MB
$
```

## Create the container

This creates the runtime container:
```
$ make container
if [ ! -d "/cache/src/firestorm" ] ; then  mkdir -p /cache/src/firestorm ; fi
docker create \
	--tmpfs /tmp --tmpfs /run \
	--name firestorm-debian-stretch \
	--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
	--mount type=bind,source=/cache/src/firestorm,destination=/local/src/firestorm \
	firestorm/debian:stretch
583967e7055b59701d13995a614f4d3f7c2cdd93a0a3adf23eece5218b216f19
$
```

## Start the container

```
$ make start
docker start firestorm-debian-stretch
firestorm-debian-stretch
583967e7055b        firestorm/debian:stretch   "/lib/systemd/systemd"   2 minutes ago  Up 10 seconds  firestorm-debian-stretch
$
```

## Synchronise the user accounts from host to container

```
$ make setup
docker exec firestorm-debian-stretch cp-user lmiphay lmiphay 1004 1009
docker exec firestorm-debian-stretch chown lmiphay:lmiphay /local/src/firestorm

drwxr-xr-x 1 lmiphay lmiphay  64 Oct 28 18:31 fs-build-variables
drwxr-xr-x 1 lmiphay lmiphay 454 Oct 29 19:36 phoenix-firestorm
$
```

## Clone/Update the repos

```
$ make clone_update
<TBD>
...
$
```

## Remove the build container and image

*This is a destructive operation:*
```
$ make  clean
docker rm --force firestorm-debian-stretch
firestorm-debian-stretch
docker rmi --force firestorm/debian:stretch
Untagged: firestorm/debian:stretch
Deleted: sha256:185cf7a645e9701cdfaee4d50e4a833c09e5ad6a5a57f5964c95dd5e5943f3af
Deleted: sha256:d17400dae2ed65a8516816a14f9b5d3aedeb128371542adef1904ea197d0c775
Deleted: sha256:7b9fcf2d2053b5d2c729553fa2fa0373a08682c06e85a91d44b522875ee9f35e
Deleted: sha256:5a612ed3fc23bdc7cea17ba5de5c4f14c9fceaa1002823e398523ab7a0af0a59
Deleted: sha256:c6125d7d94ab43dfb458feb365a09347f1bdcac5ccd90ff7ecc6bc77a2acbaf9
Deleted: sha256:2cfed00a44e432cc78aa90f8b59e30cf318278cfe1175c9d733f2e70ca1eac52
Deleted: sha256:f068ab0d2d8422b15263e08ff96694498692f3b5f9735a5977434d2a2b38bd35
Deleted: sha256:1c7f9a785b6fdf2bc5e0e11badf127a670a9c515bee2f7cb54e7286288e5030e
Deleted: sha256:2de1efdf2c6ed70f91940ff74fd3376af8a68f1c977f41d41168ba7f4941f4b5
Deleted: sha256:38398229824adc814344f9b7c5b93c777230ed5e935966dcac8633cc076be2cf
Deleted: sha256:c8a2ead9d23e2226248302147ed1a7859d771bc8d6b3adb9d84206ca635aa82d
Deleted: sha256:1695857853657771381b1ec2553088101bbaefd0c4114db369e245a01d30db6c
Deleted: sha256:6eede45238b382f12ef937a51503e4d3527e6c7ab65a71c680de441b464b8e83
Deleted: sha256:731e70e29366712957605e83d59fd00d48927d6443119a478da9363b1e6232f8
Deleted: sha256:0aca2d6439d81c7a28184555943e8746258e51e67df7f82aaa5b73f1306ae44f
$
```

Note that this doesn't remove the repos or the base debian container.

# References

+ [Firestorm git transition ticket](https://jira.firestormviewer.org/browse/FIRE-29226)
+ [Firestorm Windows build with git](https://wiki.firestormviewer.org/fs_compiling_firestorm_windows)
+ [Firestorm Debian build](https://wiki.firestormviewer.org/fs_compiling_firestorm_alexivy_debian_9)
+ [Autobuild](http://wiki.secondlife.com/wiki/Autobuild)
+ [Transition to git](https://lists.secondlife.com/pipermail/opensource-dev/2019-August/010647.html)
+ [Bitbucket sunsetting mercurial (dates)](https://bitbucket.org/blog/sunsetting-mercurial-support-in-bitbucket)
