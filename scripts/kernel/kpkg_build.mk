ifeq ($(BUILD_DIR),)
$(error BUILD_DIR must be defined on invocation)
endif

#show = $(info $(1): $($(1)))

debian_dir := $(BUILD_DIR)/debian
kpkg_dir := /usr/share/kernel-package

# FIXME: including minimal.mk stains kernel source tree (by kernel_version.mk)
# Consider managing without these includes. Now it is very slow performance.

override SRCTOP := $(BUILD_DIR)
include $(kpkg_dir)/ruleset/minimal.mk
include $(kpkg_dir)/ruleset/misc/pkg_names.mk
# clean garbage kernel-package did (see FIXME above)
# $(shell $(MAKE) mrproper)

#$(call show,TMPTOP)
#$(call show,package)

KERNEL_ARCH := $(if $(ARCH),$(ARCH),i386)
do_clean := NO
# relative from $(BUILD_DIR)
IMAGEDIR := boot

KBUILD_SRC := ./
KBUILD_OUTPUT := $(BUILD_DIR)
override dot-config := 0
include Makefile
$(info KCONFIG_CONFIG: $(KCONFIG_CONFIG))
unexport KBUILD_SRC KBUILD_OUTPUT dot-config
# to get CONFIG_LOCALVERSION to set LOCALVERSION variable and get right KERNELRELEASE
include $(BUILD_DIR)/$(KCONFIG_CONFIG)

UTS_RELEASE_HEADER := include/linux/utsrelease.h
KERNELRELEASE := $(shell cat $(BUILD_DIR)/include/config/kernel.release 2> /dev/null)
UTS_RELEASE_VERSION := $(KERNELRELEASE)
LOCALVERSION := $(shell echo $(CONFIG_LOCALVERSION))

package := $(i_package)
CHANGES_FILE := ../$(package)_$(debian).changes
TMPTOP := ./debian/$(i_package)
INT_IMAGE_DESTDIR := $(TMPTOP)/$(IMAGEDIR)

$(info package: $(package))
$(info TMPTOP: $(TMPTOP))

$(info KBUILD_IMAGE: $(KBUILD_IMAGE))
$(info KERNELRELEASE: $(KERNELRELEASE))
$(info DEB_HOST_ARCH: $(DEB_HOST_ARCH))

CONFIG_FILE := $(KCONFIG_CONFIG)
config := $(KCONFIG_CONFIG)

kimagesrc := $(KBUILD_IMAGE)
kimagedest = $(INT_IMAGE_DESTDIR)/vmlinuz-$(KERNELRELEASE)

# from rules: root_run_command
# TODO: utilise fakeroot
root_run_command=$(MAKE) -f $(DEBDIR)/ruleset/local.mk which_debdir=DEBDIR=./debian
# INSTALL=fakeroot install

package_target := debian/stamp/binary/pre-$(i_package)

export
$(info EXTRAVERSION: $(EXTRAVERSION))
$(info LOCALVERSION: $(LOCALVERSION))
$(info kimagesrc: $(kimagesrc))
$(info kimagedest: $(kimagedest))

stamp_conf:
	mkdir -p $(debian_dir)/stamp/conf
	echo skipped > $(debian_dir)/stamp/conf/kernel-conf

$(debian_dir)/stamp/doc_link: stamp_conf
	[ -L $(BUILD_DIR)/Documentation ] || \
	ln -s `realpath Documentation` $(BUILD_DIR)/Documentation
	echo done > $@

$(debian_dir)/ChangeLog: $(debian_dir)/stamp/doc_link
	$(MAKE) -C $(BUILD_DIR) -f $(kpkg_dir)/ruleset/minimal.mk debian
	po2debconf $(BUILD_DIR)/debian/templates.in > $(BUILD_DIR)/debian/templates.l10n

# TODO: right generation of buildinfo and Buildinfo
$(debian_dir)/buildinfo: $(debian_dir)/ChangeLog
	touch $@

$(BUILD_DIR)/conf.vars: $(debian_dir)/buildinfo
	touch $@

kpkg_package: $(BUILD_DIR)/conf.vars
	rm -rf $(debian_dir)/stamp/binary
	rm -rf $(debian_dir)/stamp/install
	fakeroot $(MAKE) -C $(BUILD_DIR) -f $(debian_dir)/ruleset/local.mk which_debdir=DEBDIR=./debian $(package_target)

install_repository:
	cd $(BUILD_DIR); \
	dpkg-genchanges -b -q > $(CHANGES_FILE)


debian_dir: $(debian_dir)/ChangeLog

.PHONY: kpkg_package stamp_conf debian_dir
