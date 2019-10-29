AS_USER ?= $(system id -un):$(system id -gn)

SRC ?= /cache/src/firestorm
BASE_DIR ?= /local/src/firestorm

VERSION ?= stretch
IMAGE ?= firestorm/debian:$(VERSION)
CONTAINER ?= firestorm-debian-$(VERSION)
AUTOBUILD_BUILD_ID ?= $(USER)-$(shell date +'%F-%T')

EXEC_CMD = \
	docker exec \
		--workdir $(BASE_DIR)/phoenix-firestorm-lgpl \
		--env AUTOBUILD_VARIABLES_FILE=$(BASE_DIR)/fs-build-variables/variables \
		--env AUTOBUILD_VARIABLES_ID=$(AUTOBUILD_BUILD_ID) \
		--env PATH=/usr/local/bin:/usr/bin:/bin \
		--user $(AS_USER) \
		$(CONTAINER)

all: settings pull image container start

.PHONY: settings pull image container start setup clone_update configure compile run

pull:
	docker pull debian:$(VERSION)

image:
	docker build --progress=plain --tag $(IMAGE) .

#
# TODO: replace "--privileged=true" with "--tmpfs /tmp --tmpfs /run"
#
container:
	@mkdir -p $(SRC)
	docker create \
		--privileged=true \
		--name $(CONTAINER) \
		--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
		--mount type=bind,source=$(SRC),destination=$(BASE_DIR) \
		$(IMAGE)

build: start setup clone_update configure compile

start:
	docker start $(CONTAINER)

setup:
	docker exec $(CONTAINER) cp-user $(system ./cp-user)
	docker exec $(CONTAINER) chown $(AS_USER) $(BASE_DIR)

clone_update:
	$(EXEC_CMD) clone-or-update /local/src/firestorm

configure:
	$(EXEC_CMD) autobuild configure -A 64 -c ReleaseFS_open

compile:
	$(EXEC_CMD) autobuild build -A 64 -c ReleaseFS_open
	@ls -l $(SRC)/phoenix-firestorm-lgpl/build-linux-x86_64/newview/*.xz

run:
	cd $(SRC)/phoenix-firestorm-lgpl/build-linux-x86_64/newview/packaged && ./firestorm

settings:
	@echo -n " SRC=$(SRC) BASE_DIR=$(BASE_DIR) USER=$(AS_USER) VERSION=$(VERSION) IMAGE=$(IMAGE) CONTAINER=$(CONTAINER)"

clean:
	docker rm --force $(CONTAINER)
	docker rmi --force $(IMAGE)
