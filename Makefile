FD_DEBIAN_VERSION ?= stretch
FD_FIRESTORM_IMAGE ?= firestorm/debian:$(FD_DEBIAN_VERSION)
FD_FIRESTORM_CONTAINER ?= firestorm-debian-$(FD_DEBIAN_VERSION)
FD_HOST_REPOS_DIR ?= /cache/src/firestorm

FD_CONTAINER_REPOS_DIR ?= /local/src/firestorm
FD_CONTAINER_USER_GROUP ?= $(shell id -un):$(shell id -gn)

FD_AUTOBUILD_BUILD_ID ?= $(shell hostname)-$(shell date +'%F-%T')

FD_BASE_URL ?= https://vcs.firestormviewer.org
FD_REPOS ?= autobuild-1.1 fs-build-variables phoenix-firestorm

EXEC_CMD = \
	docker exec \
		--workdir $(FD_CONTAINER_REPOS_DIR)/phoenix-firestorm \
		--env AUTOBUILD_VARIABLES_FILE=$(FD_CONTAINER_REPOS_DIR)/fs-build-variables/variables \
		--env AUTOBUILD_VARIABLES_ID=$(FD_AUTOBUILD_BUILD_ID) \
		--env PATH=/usr/local/bin:/usr/bin:/bin \
		--user $(FD_CONTAINER_USER_GROUP) \
		$(FD_FIRESTORM_CONTAINER)

nocmd: help

all: settings image container start

.PHONY: nocmd all settings pullimage image container build start setup clone pull configure compile run clean help

.EXPORT_ALL_VARIABLES:

settings:
	@env | egrep 'FD_' | sort

pullimage:
	docker pull debian:$(FD_DEBIAN_VERSION)

image:
	docker build --progress=plain --tag $(FD_FIRESTORM_IMAGE) .
	@docker images | grep firestorm/debian

#
# TODO: replace "--privileged=true" with "--tmpfs /tmp --tmpfs /run"
#		--privileged=true \
#
container:
	if [ ! -d "$(FD_HOST_REPOS_DIR)" ] ; then  mkdir -p $(FD_HOST_REPOS_DIR) ; fi
	docker create \
		--tmpfs /tmp --tmpfs /run \
		--name $(FD_FIRESTORM_CONTAINER) \
		--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
		--mount type=bind,source=$(FD_HOST_REPOS_DIR),destination=$(FD_CONTAINER_REPOS_DIR) \
		$(FD_FIRESTORM_IMAGE)

build: start setup clone_update configure compile

start:
	docker start $(FD_FIRESTORM_CONTAINER)
	@docker ps

shell:
	docker exec -it $(FD_FIRESTORM_CONTAINER) /bin/bash

copy-user:
	docker exec $(FD_FIRESTORM_CONTAINER) groupadd --force --gid $(shell id -g) $(shell id -gn)
	docker exec $(FD_FIRESTORM_CONTAINER) useradd --uid $(shell id -u) --gid $(shell id -g) $(USER)
	docker exec $(FD_FIRESTORM_CONTAINER) chown $(FD_CONTAINER_REPOS_DIR)
	@docker exec $(FD_FIRESTORM_CONTAINER) ls -l $(FD_CONTAINER_REPOS_DIR)

clone:
	for repo in $(FD_REPOS) ; do $(EXEC_CMD) git clone $(FD_BASE_URL)/$$repo $(FD_CONTAINER_REPOS_DIR)/$$repo ; done

pull:
	for repo in $(FD_REPOS) ; do $(EXEC_CMD) git pull $(FD_CONTAINER_REPOS_DIR)/$$repo ; done

configure:
	$(EXEC_CMD) autobuild configure -A 64 -c ReleaseFS_open

compile:
	$(EXEC_CMD) autobuild build -A 64 -c ReleaseFS_open
	@ls -l $(FD_HOST_REPOS_DIR)/phoenix-firestorm/build-linux-x86_64/newview/*.xz

run:
	cd $(FD_HOST_REPOS_DIR)/phoenix-firestorm/build-linux-x86_64/newview/packaged && ./firestorm

clean:
	-docker rm --force $(FD_FIRESTORM_CONTAINER)
	-docker rmi --force $(FD_FIRESTORM_IMAGE)
	@echo ""
	@docker ps -a
	@echo ""
	@docker images

help:
	@echo "settings - list the current settings"
	@echo "image - make the docker image"
	@echo "container - create the container"
	@echo "start - start the container"
	@echo "shell - start a shell on the container"
	@echo "copy-user - copy user:group into the container"
	@echo "clone - clone the projects"
	@echo "pull - update the projects"
	@echo "configure - the project"
	@echo "compile - the project"
	@echo "run - execute the binary built by compile"
	@echo "clean - remove container and image"
