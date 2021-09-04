.PHONY: all defconfig menuconfig savedefconfig image clean

all: defconfig image

defconfig:
	$(MAKE) -C buildroot BR2_EXTERNAL=$(CURDIR) O=$(CURDIR)/output beaglebone_development_defconfig

menuconfig:
	$(MAKE) -C buildroot BR2_EXTERNAL=$(CURDIR) O=$(CURDIR)/output menuconfig

savedefconfig:
	$(MAKE) -C buildroot BR2_EXTERNAL=$(CURDIR) O=$(CURDIR)/output savedefconfig

image:
	$(MAKE) -C buildroot BR2_EXTERNAL=$(CURDIR) O=$(CURDIR)/output

clean:
	$(MAKE) -C buildroot BR2_EXTERNAL=$(CURDIR) O=$(CURDIR)/output clean
