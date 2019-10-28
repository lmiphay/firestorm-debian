VERSION ?= stretch
IMAGE ?= firestorm/debian:$(VERSION)
CONTAINER ?= firestorm-debian-$(VERSION)
SRC ?= /local/src/firestorm

EXEC_CMD = \
	docker exec \
		--workdir $(SRC)/phoenix-firestorm-lgpl \
		--env AUTOBUILD_VARIABLES_FILE=$(SRC)/fs-build-variables/variables \
		--env PATH=/usr/local/bin:/usr/bin:/bin \
		$(CONTAINER)

all: settings pull image container start

.PHONY: settings pull image container start configure compile run

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
		--mount type=bind,source=$(SRC),destination=/local/src/firestorm \
		$(IMAGE)

clone: $(SRC)/phoenix-firestorm-lgpl $(SRC)/fs-build-variables

$(SRC)/phoenix-firestorm-lgpl:
	hg clone https://hg.firestormviewer.org/phoenix-firestorm-lgpl $@
	chown root:root /local/src/firestorm/phoenix-firestorm-lgpl/.hg/hgrc

$(SRC)/fs-build-variables:
	hg clone https://hg.firestormviewer.org/fs-build-variables $@

build: start configure compile

start:
	docker start $(CONTAINER)

configure:
	$(EXEC_CMD) autobuild configure --id $(USER)-$(shell date +'%F-%T') -A 64 -c ReleaseFS_open

compile:
	$(EXEC_CMD) autobuild build -A 64 -c ReleaseFS_open

run:
	cd $(SRC)/phoenix-firestorm-lgpl/build-linux-x86_64/newview/packaged && ./firestorm

settings:
	@echo -n "VERSION=$(VERSION) IMAGE=$(IMAGE) CONTAINER=$(CONTAINER) SRC=$(SRC)"

clean:
	docker rm --force $(CONTAINER)
	docker rmi --force $(IMAGE)
