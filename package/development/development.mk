################################################################################
#
# development
#
################################################################################

DEVELOPMENT_VERSION = 0.1
DEVELOPMENT_SITE = "${BR2_EXTERNAL_EBPF_PATH}/package/development"
DEVELOPMENT_SITE_METHOD = local
DEVELOPMENT_DEPENDENCIES = ply

define DEVELOPMENT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/fstab $(TARGET_DIR)/etc/
	$(INSTALL) -D -m 0755 $(@D)/self-test.sh $(TARGET_DIR)/root/
	$(INSTALL) -D -m 0755 $(@D)/test.sh $(TARGET_DIR)/root/
	$(INSTALL) -D -m 0755 $(@D)/count-syscalls.ply $(TARGET_DIR)/root/
	$(INSTALL) -D -m 0755 $(@D)/read-dist.ply $(TARGET_DIR)/root/
	$(INSTALL) -D -m 0755 $(@D)/i2c-stack.ply $(TARGET_DIR)/root/
	$(INSTALL) -D -m 0755 $(@D)/opensnoop.ply $(TARGET_DIR)/root/
	$(INSTALL) -D -m 0755 $(@D)/execsnoop.ply $(TARGET_DIR)/root/
endef

$(eval $(generic-package))
