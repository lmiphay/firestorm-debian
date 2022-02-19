FD_UBUNTU_VERSION ?= 18.04
FD_FIRESTORM_IMAGE ?= firestorm/ubuntu:$(FD_UBUNTU_VERSION)
FD_FIRESTORM_CONTAINER ?= firestorm-ubuntu-$(FD_UBUNTU_VERSION)
FD_HOST_REPOS_DIR ?= /local/src/firestorm

FD_CONTAINER_REPOS_DIR ?= /local/src/firestorm
FD_CONTAINER_USER_GROUP ?= $(shell id -un):$(shell id -gn)

FD_AUTOBUILD_BUILD_ID ?= $(shell hostname)-$(shell date +'%F-%T')

FD_BASE_URL ?= https://vcs.firestormviewer.org
FD_REPOS ?= autobuild-1.1 fs-build-variables phoenix-firestorm

EXEC_CMD = \
	docker exec \
		--user $(FD_CONTAINER_USER_GROUP) \
		$(FD_FIRESTORM_CONTAINER)

BUILD_CMD = \
	docker exec \
		--workdir $(FD_CONTAINER_REPOS_DIR)/phoenix-firestorm \
		--env AUTOBUILD_VARIABLES_FILE=$(FD_CONTAINER_REPOS_DIR)/fs-build-variables/variables \
		--env AUTOBUILD_VARIABLES_ID=$(FD_AUTOBUILD_BUILD_ID) \
		--env PATH=/usr/local/bin:/usr/bin:/bin \
		--user $(FD_CONTAINER_USER_GROUP) \
		$(FD_FIRESTORM_CONTAINER)

nocmd: help

all: settings image container start

.PHONY: nocmd all settings pullimage image container build start copy-user clone pull configure compile run clean help

.EXPORT_ALL_VARIABLES:

settings:
	@env | egrep 'FD_' | sort | awk -F'=' '{print $$1 "=" "\"" $$2 "\""}'
	@echo -ne "\nexport "; env | egrep 'FD_' | sort | awk -F'=' '{printf $$1 " "}'; echo ""

pullimage:
	docker pull ubuntu:$(FD_UBUNTU_VERSION)

image:
	docker build --progress=plain --tag $(FD_FIRESTORM_IMAGE) \
		--build-arg FD_UBUNTU_VERSION=$(FD_UBUNTU_VERSION) \
		.
	@docker images | grep firestorm/ubuntu

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
	docker exec --user $(FD_CONTAINER_USER_GROUP) -it $(FD_FIRESTORM_CONTAINER) /bin/bash

rootshell:
	docker exec -it $(FD_FIRESTORM_CONTAINER) /bin/bash

copy-user:
	docker exec $(FD_FIRESTORM_CONTAINER) groupadd --force --gid $(shell id -g) $(shell id -gn)
	docker exec $(FD_FIRESTORM_CONTAINER) useradd --uid $(shell id -u) --gid $(shell id -g) $(USER)
	docker exec $(FD_FIRESTORM_CONTAINER) chown $(FD_CONTAINER_USER_GROUP) $(FD_CONTAINER_REPOS_DIR)
	@docker exec $(FD_FIRESTORM_CONTAINER) ls -l $(FD_CONTAINER_REPOS_DIR)

clone:
	for repo in $(FD_REPOS) ; do $(EXEC_CMD) git clone $(FD_BASE_URL)/$$repo $(FD_CONTAINER_REPOS_DIR)/$$repo ; done

pull:
	for repo in $(FD_REPOS) ; do $(EXEC_CMD) git -C $(FD_CONTAINER_REPOS_DIR)/$$repo pull ; done

configure:
	$(BUILD_CMD) autobuild configure --verbose -A 64 -c ReleaseFS_open

compile:
	$(BUILD_CMD) autobuild build -A 64 -c ReleaseFS_open
	@ls -l $(FD_HOST_REPOS_DIR)/phoenix-firestorm/build-linux-x86_64/newview/*.xz

uninstall:
	$(BUILD_CMD) autobuild configure -A 64 -c ReleaseFS_open -- --clean
#$(BUILD_CMD) autobuild uninstall colladadom icu4c boost -A 64 --verbose
#$(BUILD_CMD) autobuild uninstall dullahan_gcc5 -A 64 --verbose

print:
	$(BUILD_CMD) autobuild print -A 64

run:
	cd $(FD_HOST_REPOS_DIR)/phoenix-firestorm/build-linux-x86_64/newview/packaged && ./firestorm

clean_packages:
	docker exec $(FD_FIRESTORM_CONTAINER) rm -rf $(FD_CONTAINER_REPOS_DIR)/phoenix-firestorm/build-linux-x86_64/packages

clean:
	-docker rm --force $(FD_FIRESTORM_CONTAINER)
	-docker rmi --force $(FD_FIRESTORM_IMAGE)
	@echo ""
	@docker ps -a
	@echo ""
	@docker images

help:
	@echo "settings - list the current settings"
	@echo "pullimage - pull down the base ubuntu $(FD_UBUNTU_VERSION) image"
	@echo "image - create the docker image"
	@echo "container - create the docker container"
	@echo "start - start the container"
	@echo "copy-user - copy $(FD_CONTAINER_USER_GROUP) into the container"
	@echo "shell - start a user shell on the container"
	@echo "rootshell - start a rootshell on the container"
	@echo "clone - clone the projects"
	@echo "pull - update the projects"
	@echo "configure - the project"
	@echo "compile - the project"
	@echo "run - execute the binary built by compile"
	@echo "clean_packages - remove all installed packages (when nothing else works)"
	@echo "clean - remove container and image"
