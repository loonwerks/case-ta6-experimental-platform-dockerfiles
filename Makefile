DOCKERHUB ?= 
PREFIX ?= case-ta6-
DOCKER_TAG ?= p2pa1
BASE_TOOLS_IMG ?= $(PREFIX)tools:$(DOCKER_TAG)
ODROID_XU4_TOOLS_IMG ?= $(PREFIX)odroid-xu4-tools:$(DOCKER_TAG)
ODROID_XU4_BUILD_IMG ?= $(PREFIX)odroid-xu4-build:$(DOCKER_TAG)
UXAS_TOOLS_IMG ?= $(PREFIX)uxas-tools:$(DOCKER_TAG)
UXAS_TEST_IMG ?= $(PREFIX)uxas-build:$(DOCKER_TAG)
EXTRAS_IMG := $(PREFIX)extras
USER_IMG := $(PREFIX)user-img
USER_BASE_IMG := $(UXAS_TOOLS_IMG)
HOST_DIR ?= $(shell pwd)

DOCKER_BUILD ?= docker build
DOCKER_FLAGS ?= --force-rm=true


################################################
# Build dependencies for Linux and OpenUxAS
#################################################
.PHONY: base_tools rebuild_base_tools
base_tools:
	docker pull debian:stretch
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		-f case-ta6-tools.dockerfile \
		-t $(BASE_TOOLS_IMG) \
		.
rebuild_base_tools: DOCKER_FLAGS += --no-cache
rebuild_base_tools: base_tools

.PHONY: odroid_xu4_tools rebuild_odroid_xu4_tools
odroid_xu4_tools: base_tools
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(BASE_TOOLS_IMG) \
		-f case-ta6-odroid-xu4-tools.dockerfile \
		-t $(DOCKERHUB)$(ODROID_XU4_TOOLS_IMG) \
		.
rebuild_odroid_xu4_tools: DOCKER_FLAGS += --no-cache
rebuild_odroid_xu4_tools: odroid_xu4_tools

.PHONY: odroid_xu4_build rebuild_odroid_xu4_build
odroid_xu4_build: odroid_xu4_tools
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(ODROID_XU4_TOOLS_IMG) \
		-f case-ta6-odroid-xu4-build.dockerfile \
		-t $(DOCKERHUB)$(ODROID_XU4_BUILD_IMG) \
		.
rebuild_odroid_xu4_build: DOCKER_FLAGS += --no-cache
rebuild_odroid_xu4_build: odroid_xu4_build

.PHONY: uxas_tools rebuild_uxas_tools
uxas_tools: odroid_xu4_build
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg BASE_IMG=$(ODROID_XU4_BUILD_IMG) \
		-f case-ta6-uxas-tools.dockerfile \
		-t $(DOCKERHUB)$(UXAS_TOOLS_IMG) \
		.
rebuild_uxas_tools: DOCKER_FLAGS += --no-cache
rebuild_uxas_tools: uxas_tools

.PHONY: all
all: base_tools odroid_xu4_tools odroid_xu4_build uxas_tools

.PHONY: rebuild_all
rebuild_all: rebuild_base_tools rebuild_odroid_xu4_tools rebuild_odroid_xu4_build rebuild_uxas_tools


################################################
# Testing if the dependencies are still working
#################################################
.PHONY: run_tests
run_tests: test_uxas_build
rerun_tests: DOCKER_FLAGS += --no-cache
rerun_tests: run_tests

.PHONY: test_uxas
test_uxas: 
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg UXAS_TOOLS_IMG=$(DOCKERHUB)$(UXAS_TOOLS_IMG) \
		-f case-ta6-uxas-build.dockerfile \
		-t $(UXAS_TEST_IMG) \
		.
retest_uxas: DOCKER_FLAGS += --no-cache
retest_uxas: test_uxas

################################################
# Making docker easier to use by mapping current
# user into a container.
#################################################
.PHONY: pull_odroid_xu4_tools_image
pull_odroid_xu4_tools_image:
	docker pull $(DOCKERHUB)$(ODROID_XU4_TOOLS_IMG)

.PHONY: pull_odroid_xu4_build_image
pull_odroid_xu4_build_image:
	docker pull $(DOCKERHUB)$(ODROID_XU4_BUILD_IMG)

.PHONY: pull_uxas_tools_image
pull_uxas_tools_image:
	docker pull $(DOCKERHUB)$(UXAS_TOOLS_IMG)

.PHONY: pull_images_from_dockerhub
pull_images_from_dockerhub: pull_odroid_xu4_tools_image pull_odroid_xu4_build_image pull_uxas_tools_image


################################################
# Making docker easier to use by mapping current
# user into a container.
#################################################
.PHONY: user
user: user_uxas_tools  # use UxAS as the default

.PHONY: user_odroid_xu4_tools
user_odroid_xu4_tools: build_user_odroid_xu4_tools user_run

.PHONY: user_odroid_xu4_build
user_odroid_xu4_build: build_user_odroid_xu4_build user_run

.PHONY: user_uxas_tools
user_uxas_tools: build_user_uxas_tools user_run

.PHONY: user_run
user_run: 
	docker run \
		-it \
		--hostname in-container \
		--rm \
		-u $(shell whoami) \
		-v $(HOST_DIR):/host \
		$(USER_IMG)-$(shell id -u) bash


.PHONY: build_user
build_user:
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg=USER_BASE_IMG=$(DOCKERHUB)$(USER_BASE_IMG) \
		-f extras.dockerfile \
		-t $(EXTRAS_IMG) \
		.
	$(DOCKER_BUILD) $(DOCKER_FLAGS) \
		--build-arg=EXTRAS_IMG=$(EXTRAS_IMG) \
		--build-arg=UNAME=$(shell whoami) \
		--build-arg=UID=$(shell id -u) \
		-f user.dockerfile \
		-t $(USER_IMG)-$(shell id -u) .
build_user_odroid_xu4_tools: USER_BASE_IMG = $(ODROID_XU4_TOOLS_IMG)
build_user_odroid_xu4_tools: build_user
build_user_odroid_xu4_build: USER_BASE_IMG = $(ODROID_XU4_TOOLS_IMG)
build_user_odroid_xu4_build: build_user
build_user_uxas_tools: USER_BASE_IMG = $(UXAS_TOOLS_IMG)
build_user_uxas_tools: build_user

.PHONY: clean_home_dir
clean_home_dir:
	docker volume rm $(shell whoami)-home

.PHONY: clean_data
clean_data: clean_home_dir

.PHONY: clean_images
clean_images:
	-docker rmi $(USER_IMG)-$(shell id -u) 
	-docker rmi $(DOCKERHUB)$(BASE_TOOLS_IMG)
	-docker rmi $(DOCKERHUB)$(ODROID_XU4_TOOLS_IMG)
	-docker rmi $(DOCKERHUB)$(ODROID_XU4_TOOLS_IMG)
	-docker rmi $(DOCKERHUB)$(UXAS_TOOLS_IMG)
	-docker rmi extras

.PHONY: clean
clean: clean_data clean_images
