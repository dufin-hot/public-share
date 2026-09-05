SSV6X5X_VERSION = local
SSV6X5X_SITE = $(BR2_EXTERNAL_RK322X_SERVER_PATH)/package/ssv6x5x/src
SSV6X5X_SITE_METHOD = local

SSV6X5X_MODULE_SUBDIRS = .

define SSV6X5X_INSTALL_FIRMWARE
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_RK322X_SERVER_PATH)/package/ssv6x5x/firmware/ssv6x5x-sw.bin \
		$(TARGET_DIR)/lib/firmware/ssv6x5x-sw.bin

	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_RK322X_SERVER_PATH)/package/ssv6x5x/firmware/ssv6x5x-wifi.cfg \
		$(TARGET_DIR)/lib/firmware/ssv6x5x-wifi.cfg
endef

SSV6X5X_POST_INSTALL_TARGET_HOOKS += SSV6X5X_INSTALL_FIRMWARE

$(eval $(kernel-module))
$(eval $(generic-package))
