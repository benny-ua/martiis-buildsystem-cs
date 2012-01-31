STLINUX     = stlinux24
STLINUX_DIR = $(BUILD_TMP)/$(STLINUX)

## not yet needed
HOST_ARCH := $(shell uname -m)

RPMS        = $(STLINUX_DIR)/RPMS
RPMS_ARCH   = $(STLINUX_DIR)/RPMS/$(HOST_ARCH)
RPMS_NOARCH = $(STLINUX_DIR)/RPMS/noarch
SPECS       = $(STLINUX_DIR)/SPECS
SOURCES     = $(STLINUX_DIR)/SOURCES
STL_PATCHES = $(PATCHES)/stlinux
STM_RELOCATE = /opt/STM/STLinux-2.4

DRPM = --macros /usr/lib/rpm/macros:$(STLINUX_DIR)/config/rpm/targets/sh4-linux:$(STLINUX_DIR)/config/rpm/common:$(STLINUX_DIR)/localmacros
DRPMBUILD = --macros /usr/lib/rpm/macros:$(STLINUX_DIR)/config/rpm/targets/sh4-linux:$(STLINUX_DIR)/config/rpm/common:$(STLINUX_DIR)/localmacros

## most of the entries are not yet needed...
$(STLINUX_DIR)/localmacros:
	rm -f $@
	echo "%_topdir $(STLINUX_DIR)" >> $@
	echo "%_specdir %_topdir/SPECS" >> $@
	echo "%_sourcedir %_topdir/SOURCES" >> $@
	echo "%_builddir %_topdir/BUILD" >> $@
	echo "%_buildrootdir %_topdir/BUILDROOT" >> $@
	echo "%buildroot %_topdir/BUILDROOT/%{name}-%{version}-%{release}.x86_64" >> $@
	echo "%_rpmdir %_topdir/RPMS" >> $@
	echo "%_srcrpmdir %_topdir/SRPMS" >> $@
	echo "%_stm_install_prefix $(STLINUX_DIR)" >> $@
	echo "%_stm_base_prefix $(STLINUX_DIR)/base" >> $@
	echo "%_stm_host_dir $(STLINUX_DIR)/host" >> $@
	echo "%_stm_cross_dir $(CROSS_DIR)" >> $@
	echo "%_stm_config_dir $(STLINUX_DIR)/config" >> $@
	echo "%_stm_devkit_dir $(STLINUX_DIR)/devkit" >> $@
	echo "%_stm_cross_target_dir $(TARGETPREFIX)" >> $@
	echo "%_stm_kernel_dir $(STLINUX_DIR)/kernel" >> $@
	echo "%_stm_sources_dir $(STLINUX_DIR)/kernel" >> $@
	echo "%_stm_host_arch `uname -m`" >> $@
	echo "%_stm_host_cpu `uname -m`" >> $@
	echo "%_stm_host_config `uname -m`-unknown-linux-gnu" >> $@
	echo "%_dbpath $(STLINUX_DIR)/cdkroot-rpmdb" >> $@
	echo "%__bzip2 /usr/bin/bzip2" >> $@
	echo "%nohostbuilddeps 1" >> $@
	echo "%_default_patch_fuzz 2" >> $@

## have your stlinux ISOs in this place...
STLINUX_ISODIR ?= /space/iso/stlinux
STLINUX_SH4_ISO = $(STLINUX_ISODIR)/STLinux-2.4-sh4-20100401.iso
STLINUX_SRC_ISO = $(STLINUX_ISODIR)/STLinux-2.4-source-20111019.iso
STLINUX_SH4_MNT = $(BUILD_TMP)/iso/sh4
STLINUX_SRC_MNT = $(BUILD_TMP)/iso/src
ST_SH4_RPMS = $(STLINUX_SH4_MNT)/STLinux/sh4

# updates / downloads
STL_ARCHIVE = $(ARCHIVE)/stlinux
STL_FTP = http://ftp.stlinux.com/pub/stlinux/2.4
STL_GET = $(WGET)/stlinux

$(STL_ARCHIVE)/stlinux24-host-kernel-source-sh4-2.6.32.46_stm24_0209-209.src.rpm:
	$(STL_GET) $(STL_FTP)/updates/SRPMS/stlinux24-host-kernel-source-sh4-2.6.32.46_stm24_0209-209.src.rpm

PATCH_STR = _0209

### those patches are taken from the pingulux-git/tdt checkout
STM24_DVB_PATCH = linux-sh4-linuxdvb_stm24$(PATCH_STR).patch
COMMONPATCHES_24 = \
		$(STM24_DVB_PATCH) \
		linux-sh4-sound_stm24$(PATCH_STR).patch \
		linux-sh4-time_stm24$(PATCH_STR).patch \
		linux-sh4-init_mm_stm24$(PATCH_STR).patch \
		linux-sh4-copro_stm24$(PATCH_STR).patch \
		bpa2_procfs_stm24$(PATCH_STR).patch

SPARK_PATCHES_24 = $(COMMONPATCHES_24) \
	linux-sh4-stmmac_stm24$(PATCH_STR).patch \
	linux-sh4-lmb_stm24$(PATCH_STR).patch \
	linux-sh4-spark_setup_stm24$(PATCH_STR).patch \
	linux-sh4-linux_yaffs2_stm24_0209.patch