# build a flash image.
# the contents need to be in $(BUILD_TMP)/install
# e.g. installed with "make minimal-system-pkgs"
#
# This is totally untested :-)
#
# the needed mkfs.jffs2 and sumtool are built with the mtd-utils-host target
#

TIME := $(shell date +%Y%m%d%H%M)
FLASHIMG = $(BUILD_TMP)/flashroot-$(PLATFORM)-$(TIME).img
SUMIMG   = $(BUILD_TMP)/flashroot-$(PLATFORM)-$(TIME).sum.img

local-install:
	# copy local/flash/* into the image...
	# you can e.g. create local/flash/boot/audio.elf ...
	@if test -d $(BASE_DIR)/local/flash/; then \
		cp -a -v $(BASE_DIR)/local/flash/. $(BUILD_TMP)/install/.; \
	fi
ifeq ($(PLATFORM), spark)
ifeq ($(SPARK_ONLY), )
	# copy over the newest spark7162-drivers package,it will be installed on first boot
	if test x"`ls $(PACKAGE_DIR)/spark7162-drivers* 2>/dev/null`" != x""; then \
		cp -a `ls -1t $(PACKAGE_DIR)/spark7162-drivers*|head -1` $(BUILD_TMP)/install; \
	fi
endif
endif

flash-prepare: local-install $(HOSTPREFIX)/bin/mkfs.jffs2

flash-build: 
	echo "/dev/console c 0644 0 0 5 1 0 0 0" > $(BUILD_TMP)/devtable
	ln -sf /share/zoneinfo/CET $(BUILD_TMP)/install/etc/localtime # CET is the default in a fresh neutrino install
	mkfs.jffs2 -e 0x20000 -p -U -D $(BUILD_TMP)/devtable -d $(BUILD_TMP)/install -o $(FLASHIMG)
	sumtool    -e 0x20000 -p -i $(FLASHIMG) -o $(SUMIMG)

ifeq ($(PLATFORM), coolstream)
# the devtable is used for having a console device on first boot.
flashimage: flash-prepare cskernel flash-build
	$(REMOVE)/coolstream
	mkdir $(BUILD_TMP)/coolstream
	set -e;\
		cp $(BUILD_TMP)/Image.img mtd1-hd1.img; scripts/mkmultiboot-hd1.sh; rm mtd1-hd1.img; \
		cd $(BUILD_TMP); \
		mv kernel-autoscr-mtd1.img coolstream/kernel.img; \
		cp $(SUMIMG) coolstream/system.img
endif
ifeq ($(PLATFORM), spark)
# you should probably "make system-pkgs" before...
# this has been tested by flashing from an USB stick on GM 990
flashimage: system-pkgs plugins flash-prepare flash-build
	@set -e; rm -rf $(BUILD_TMP)/enigma2; mkdir $(BUILD_TMP)/enigma2; \
		cd $(BUILD_TMP)/enigma2; \
		cp -a $(BUILD_TMP)/uImage .; \
		cp -a $(SUMIMG) e2jffs2.img; \
		cp -a $(BASE_DIR)/misc/install_jffs2.sh $(BASE_DIR)/misc/upgrade_jffs2.sh .; \
		chmod 755 install_jffs2.sh upgrade_jffs2.sh ; \
		echo; echo; echo "SPARK flash image is in build_tmp/enigma2:"; ls -l *; \
		echo; echo "copy this directory onto an USB stick and flash via the boot loader.";
ifeq ($(SPARK_ONLY), )
	@set -e; rm -rf $(BUILD_TMP)/enigma2-7162; mkdir $(BUILD_TMP)/enigma2-7162; \
		cd $(BUILD_TMP)/enigma2-7162; \
		cp -a $(BUILD_TMP)/uImage-7162 uImage; \
		cp -a $(SUMIMG) e2jffs2.img; \
		echo; echo "SPARK7162 flash image is in build_tmp/enigma2-7162:"; ls -l *; \
		echo; echo "copy this directory onto an USB stick as 'enigma' and flash via the boot loader.";
endif
endif
ifeq ($(PLATFORM), azbox)
flashimage: flash-prepare flash-build
	set -e; cd $(BUILD_TMP); \
		curl -f -z update.ext -o update.ext -# \
			http://azbox-enigma2-project.googlecode.com/files/update.ext
	@set -e; $(REMOVE)/webif-image; mkdir $(BUILD_TMP)/webif-image; \
		cd $(BUILD_TMP)/webif-image; \
		cp -a $(BUILD_TMP)/linux-$(LINUX_AZBOX_VER)/zbimage-linux-xload .; \
		cp -a $(SUMIMG) flash.jffs2; \
		ln flash.jffs2 image0.jffs2; \
		cp -a $(BUILD_TMP)/update.ext .; \
		tar cvf webif-update.tar zbimage-linux-xload flash.jffs2; \
		zip -o usb-update.zip zbimage-linux-xload image0.jffs2 update.ext; \
		echo; echo; echo "AZbox flash image is in build_tmp/webif-image/webif-update.tar."; \
		echo "AZbox USB update is in build_tmp/webif-image/usb-update.zip."; \
		echo; echo "flash this via the rescue boot / webinterface."
endif

ifeq ($(PLATFORM), tripledragon)
flashimage:
	@echo flashimage is not a supported target for $(PLATFORM)
endif

$(HOSTPREFIX)/bin/mkfs.jffs2: mtd-utils-host

mtd-utils-host: $(ARCHIVE)/mtd-utils-$(MTD_UTILS_VER_HOST).tar.bz2 | $(HOSTPREFIX)/bin
	if test ! -d $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER_HOST)-host ; then \
		set +e; mv $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER_HOST) $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER_HOST)-target 2>/dev/null; set -e; \
		$(UNTAR)/mtd-utils-$(MTD_UTILS_VER_HOST).tar.bz2 && \
			mv $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER_HOST) $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER_HOST)-host ;\
		set +e; mv $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER_HOST)-target $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER_HOST) 2>/dev/null; set -e; \
	fi
	cd $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER_HOST)-host && \
		$(MAKE) `pwd`/mkfs.jffs2 `pwd`/sumtool BUILDDIR=`pwd` WITHOUT_XATTR=1 && \
		mv mkfs.jffs2 sumtool $(HOSTPREFIX)/bin && \
		rm -rf $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER_HOST)-host && exit ; \
		echo; echo; echo "Compiling mtd-utils on the host failed. You'll probably need"; \
		echo "to install the zlib- and/or lzo-devel packages first."

PHONY += flashimage mtd-utils-host
