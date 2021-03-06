ifeq ($(call my-dir),$(call project-path-for,recovery))

LOCAL_PATH := $(call my-dir)

# philz touch gui: either prebuilt or from sources
PHILZ_TOUCH_RECOVERY := true
# USE_PREBUILT_LIBTOUCH_GUI := true

ifdef PHILZ_TOUCH_RECOVERY
ifdef USE_PREBUILT_LIBTOUCH_GUI
include $(CLEAR_VARS)
MY_LOCAL_PATH := $(LOCAL_PATH)
ifeq ($(TARGET_CPU_VARIANT),arm11)
    LOCAL_PREBUILT_LIBS := libtouch_gui/armv6/libtouch_gui.a
else
    LOCAL_PREBUILT_LIBS := libtouch_gui/libtouch_gui.a
endif
include $(BUILD_MULTI_PREBUILT)
LOCAL_PATH := $(MY_LOCAL_PATH)
endif
endif

# start recovery binary makefile
include $(CLEAR_VARS)

commands_recovery_local_path := $(LOCAL_PATH)

#Extra BoardConfig flags
include $(commands_recovery_local_path)/boardconfig/BoardConfig.mk

# LOCAL_CPP_EXTENSION := .c

LOCAL_SRC_FILES := \
    recovery.c \
    bootloader.c \
    install.c \
    roots.c \
    ui.c \
    extendedcommands.c \
    advanced_functions.c \
    digest/md5.c \
    recovery_settings.c \
    nandroid.c \
    ../../system/core/toolbox/dynarray.c \
    ../../system/core/toolbox/newfs_msdos.c \
    edifyscripting.c \
    prop.c \
    adb_install.c \
    verifier.c \
    ../../system/vold/vdc.c \
    propsrvc/legacy_property_service.c

ADDITIONAL_RECOVERY_FILES := $(shell echo $$ADDITIONAL_RECOVERY_FILES)
LOCAL_SRC_FILES += $(ADDITIONAL_RECOVERY_FILES)

LOCAL_MODULE := recovery

LOCAL_FORCE_STATIC_EXECUTABLE := true

RECOVERY_FSTAB_VERSION := 2

ifdef I_AM_KOUSH
RECOVERY_NAME := ClockworkMod Recovery
LOCAL_CFLAGS += -DI_AM_KOUSH
else
ifndef RECOVERY_NAME
RECOVERY_NAME := CWM-based Recovery
endif
endif

# This should be the same line as upstream to not break makerecoveries.sh
RECOVERY_VERSION := $(RECOVERY_NAME) v6.0.5.1

PHILZ_BUILD := 6.58.9.1
CWM_BASE_VERSION := $(shell echo $(RECOVERY_VERSION) | cut -d ' ' -f 3)
LOCAL_CFLAGS += -DCWM_BASE_VERSION="$(CWM_BASE_VERSION)"

LOCAL_CFLAGS += -DRECOVERY_VERSION="$(RECOVERY_VERSION)"
RECOVERY_API_VERSION := 2
LOCAL_CFLAGS += -DRECOVERY_API_VERSION=$(RECOVERY_API_VERSION)

ifdef PHILZ_TOUCH_RECOVERY
    LOCAL_CFLAGS += -DPHILZ_TOUCH_RECOVERY
    RECOVERY_MOD_NAME := PhilZ Touch
else
    ifndef RECOVERY_MOD_NAME
    RECOVERY_MOD_NAME := CWM Advanced Edition
    endif
endif

RECOVERY_MOD_VERSION := $(RECOVERY_MOD_NAME) $(shell echo $(PHILZ_BUILD) | cut -d . -f 1)
RECOVERY_MOD_VERSION_BUILD := $(RECOVERY_MOD_NAME) $(PHILZ_BUILD)
LOCAL_CFLAGS += -DRECOVERY_MOD_VERSION="$(RECOVERY_MOD_VERSION)"
LOCAL_CFLAGS += -DRECOVERY_MOD_VERSION_BUILD="$(RECOVERY_MOD_VERSION_BUILD)"
LOCAL_CFLAGS += -DPHILZ_BUILD="$(PHILZ_BUILD)"
#compile date:
#LOCAL_CFLAGS += -DBUILD_DATE="\"`date`\""

ifdef PHILZ_TOUCH_RECOVERY
ifeq ($(BOARD_USE_CUSTOM_RECOVERY_FONT),)
  BOARD_USE_CUSTOM_RECOVERY_FONT := \"roboto_15x24.h\"
endif
endif

ifeq ($(BOARD_USE_CUSTOM_RECOVERY_FONT),)
  BOARD_USE_CUSTOM_RECOVERY_FONT := \"font_10x18.h\"
endif

BOARD_RECOVERY_CHAR_WIDTH := $(shell echo $(BOARD_USE_CUSTOM_RECOVERY_FONT) | cut -d _  -f 2 | cut -d . -f 1 | cut -d x -f 1)
BOARD_RECOVERY_CHAR_HEIGHT := $(shell echo $(BOARD_USE_CUSTOM_RECOVERY_FONT) | cut -d _  -f 2 | cut -d . -f 1 | cut -d x -f 2)

LOCAL_CFLAGS += -DBOARD_RECOVERY_CHAR_WIDTH=$(BOARD_RECOVERY_CHAR_WIDTH) -DBOARD_RECOVERY_CHAR_HEIGHT=$(BOARD_RECOVERY_CHAR_HEIGHT)

BOARD_RECOVERY_DEFINES := BOARD_HAS_NO_SELECT_BUTTON BOARD_RECOVERY_ALWAYS_WIPES BOARD_RECOVERY_HANDLES_MOUNT TARGET_USE_CUSTOM_LUN_FILE_PATH BOARD_UMS_LUNFILE TARGET_DEVICE TARGET_RECOVERY_FSTAB
BOARD_RECOVERY_DEFINES += BOOTLOADER_CMD_ARG BOARD_HAS_SLOW_STORAGE BOARD_USE_MTK_LAYOUT BOARD_MTK_BOOT_LABEL BOARD_RECOVERY_USE_LIBTAR BOARD_HAS_NO_MULTIUSER_SUPPORT
BOARD_RECOVERY_DEFINES += BRIGHTNESS_SYS_FILE BATTERY_LEVEL_PATH BOARD_POST_UNBLANK_COMMAND BOARD_HAS_LOW_RESOLUTION RECOVERY_TOUCHSCREEN_SWAP_XY RECOVERY_TOUCHSCREEN_FLIP_X RECOVERY_TOUCHSCREEN_FLIP_Y BOARD_USE_B_SLOT_PROTOCOL BOARD_HAS_NO_FB2PNG

# Stringify BOARD_RECOVERY_DEFINES list
$(foreach board_define,$(BOARD_RECOVERY_DEFINES), \
  $(if $($(board_define)), \
    $(eval LOCAL_CFLAGS += -D$(board_define)=\"$($(board_define))\") \
  ) \
  )

ifneq ($(BOARD_RECOVERY_BLDRMSG_OFFSET),)
  LOCAL_CFLAGS += -DBOARD_RECOVERY_BLDRMSG_OFFSET=$(BOARD_RECOVERY_BLDRMSG_OFFSET)
endif

LOCAL_STATIC_LIBRARIES :=

LOCAL_CFLAGS += -DUSE_EXT4 -DMINIVOLD
LOCAL_C_INCLUDES += system/extras/ext4_utils system/core/fs_mgr/include external/fsck_msdos
LOCAL_C_INCLUDES += system/vold

ifdef PHILZ_TOUCH_RECOVERY
LOCAL_STATIC_LIBRARIES += libtouch_gui
endif

ifneq ($(BOARD_HAS_NO_FB2PNG),true)
LOCAL_STATIC_LIBRARIES += libfb2png_static
endif

LOCAL_STATIC_LIBRARIES += libext4_utils_static libz libsparse_static

ifeq ($(ENABLE_LOKI_RECOVERY),true)
  LOCAL_CFLAGS += -DENABLE_LOKI
  LOCAL_STATIC_LIBRARIES += libloki_static
  LOCAL_SRC_FILES += loki/loki_recovery.c
endif

# This binary is in the recovery ramdisk, which is otherwise a copy of root.
# It gets copied there in config/Makefile.  LOCAL_MODULE_TAGS suppresses
# a (redundant) copy of the binary in /system/bin for user builds.
# TODO: Build the ramdisk image in a more principled way.

LOCAL_MODULE_TAGS := eng

ifeq ($(BOARD_CUSTOM_RECOVERY_KEYMAPPING),)
  LOCAL_SRC_FILES += default_recovery_keys.c
else
  LOCAL_SRC_FILES += $(BOARD_CUSTOM_RECOVERY_KEYMAPPING)
endif

ifeq ($(BOARD_CUSTOM_RECOVERY_UI),)
  LOCAL_SRC_FILES += default_recovery_ui.c
else
  LOCAL_SRC_FILES += $(BOARD_CUSTOM_RECOVERY_UI)
endif

LOCAL_STATIC_LIBRARIES += libvoldclient libsdcard libminipigz libreboot_static libfsck_msdos
LOCAL_STATIC_LIBRARIES += libmake_ext4fs libext4_utils_static libz libsparse_static

ifeq ($(BOARD_RECOVERY_USE_LIBTAR),true)
LOCAL_STATIC_LIBRARIES += libtar_recovery
endif

ifneq ($(BOARD_USE_NTFS_3G),false)
LOCAL_CFLAGS += -DBOARD_USE_NTFS_3G
LOCAL_STATIC_LIBRARIES += libmount.ntfs-3g libntfsfix.recovery libmkntfs.recovery libfuse-lite.recovery libntfs-3g.recovery
endif

ifeq ($(TARGET_USERIMAGES_USE_F2FS),true)
LOCAL_CFLAGS += -DUSE_F2FS
LOCAL_STATIC_LIBRARIES += libmake_f2fs libfsck_f2fs libfibmap_f2fs
endif

LOCAL_STATIC_LIBRARIES += libminzip libunz libmincrypt

LOCAL_STATIC_LIBRARIES += libminizip libminadbd libedify libbusybox libmkyaffs2image libunyaffs liberase_image libdump_image libflash_image
LOCAL_LDFLAGS += -Wl,--no-fatal-warnings

LOCAL_STATIC_LIBRARIES += libfs_mgr libdedupe libcrypto_static libcrecovery libflashutils libmtdutils libmmcutils libbmlutils

ifeq ($(BOARD_USES_BML_OVER_MTD),true)
LOCAL_STATIC_LIBRARIES += libbml_over_mtd
endif

LOCAL_STATIC_LIBRARIES += libminui libpixelflinger_static libpng libcutils liblog
LOCAL_STATIC_LIBRARIES += libstdc++ libc

LOCAL_STATIC_LIBRARIES += libselinux

RECOVERY_LINKS := bu make_ext4fs edify busybox flash_image dump_image mkyaffs2image unyaffs erase_image nandroid reboot volume setprop getprop start stop dedupe minizip setup_adbd fsck_msdos newfs_msdos vdc sdcard pigz

ifeq ($(BOARD_RECOVERY_USE_LIBTAR),true)
RECOVERY_LINKS += tar
endif

ifneq ($(BOARD_USE_NTFS_3G),false)
RECOVERY_LINKS += mkntfs ntfs-3g ntfsfix
endif

ifneq ($(BOARD_HAS_NO_FB2PNG),true)
    RECOVERY_LINKS += fb2png
endif

ifeq ($(TARGET_USERIMAGES_USE_F2FS),true)
RECOVERY_LINKS += mkfs.f2fs fsck.f2fs fibmap.f2fs
endif

# nc is provided by external/netcat
RECOVERY_SYMLINKS := $(addprefix $(TARGET_RECOVERY_ROOT_OUT)/sbin/,$(RECOVERY_LINKS))

BUSYBOX_LINKS := $(shell cat external/busybox/busybox-minimal.links)
exclude := tune2fs mke2fs
ifeq ($(BOARD_RECOVERY_USE_LIBTAR),true)
exclude += tar
endif
RECOVERY_BUSYBOX_SYMLINKS := $(addprefix $(TARGET_RECOVERY_ROOT_OUT)/sbin/,$(filter-out $(exclude),$(notdir $(BUSYBOX_LINKS))))

LOCAL_ADDITIONAL_DEPENDENCIES := \
    killrecovery.sh \
    parted \
    sdparted \
    su.recovery \
    install-su.sh \
    install-recovery.sh \
    99SuperSUDaemon

LOCAL_ADDITIONAL_DEPENDENCIES += \
    minivold \
    recovery_e2fsck \
    recovery_mke2fs \
    recovery_tune2fs \
    mount.exfat_static

LOCAL_ADDITIONAL_DEPENDENCIES += $(RECOVERY_SYMLINKS) $(RECOVERY_BUSYBOX_SYMLINKS)

LOCAL_ADDITIONAL_DEPENDENCIES += updater

LOCAL_ADDITIONAL_DEPENDENCIES += \
    zip \
    raw-backup.sh \
    bootscripts_mnt.sh \
    stitch.png

ifdef PHILZ_TOUCH_RECOVERY
LOCAL_ADDITIONAL_DEPENDENCIES += \
    virtual_keys.png
endif

include $(BUILD_EXECUTABLE)

$(RECOVERY_SYMLINKS): RECOVERY_BINARY := $(LOCAL_MODULE)
$(RECOVERY_SYMLINKS):
	@echo "Symlink: $@ -> $(RECOVERY_BINARY)"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf $(RECOVERY_BINARY) $@

# Now let's do recovery symlinks
$(RECOVERY_BUSYBOX_SYMLINKS): BUSYBOX_BINARY := busybox
$(RECOVERY_BUSYBOX_SYMLINKS):
	@echo "Symlink: $@ -> $(BUSYBOX_BINARY)"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf $(BUSYBOX_BINARY) $@

# Reboot static library
include $(CLEAR_VARS)
LOCAL_MODULE := libreboot_static
LOCAL_MODULE_TAGS := optional
LOCAL_CFLAGS := -Dmain=reboot_main
LOCAL_SRC_FILES := ../../system/core/reboot/reboot.c
include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := killrecovery.sh
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := RECOVERY_EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)/sbin
LOCAL_SRC_FILES := killrecovery.sh
include $(BUILD_PREBUILT)

#philz external scripts
include $(CLEAR_VARS)
LOCAL_MODULE := raw-backup.sh
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := RECOVERY_EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)/sbin
LOCAL_SRC_FILES := raw-backup.sh
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := bootscripts_mnt.sh
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := RECOVERY_EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)/sbin
LOCAL_SRC_FILES := bootscripts_mnt.sh
include $(BUILD_PREBUILT)
#end philz external scripts

include $(CLEAR_VARS)

LOCAL_SRC_FILES := verifier_test.c verifier.c

LOCAL_C_INCLUDES += system/extras/ext4_utils system/core/fs_mgr/include

LOCAL_MODULE := verifier_test

LOCAL_FORCE_STATIC_EXECUTABLE := true

LOCAL_MODULE_TAGS := tests

LOCAL_STATIC_LIBRARIES := libmincrypt libcutils libstdc++ libc

include $(BUILD_EXECUTABLE)

include $(commands_recovery_local_path)/bmlutils/Android.mk
include $(commands_recovery_local_path)/dedupe/Android.mk
include $(commands_recovery_local_path)/flashutils/Android.mk
include $(commands_recovery_local_path)/libcrecovery/Android.mk
include $(commands_recovery_local_path)/minui/Android.mk
include $(commands_recovery_local_path)/minelf/Android.mk
include $(commands_recovery_local_path)/minzip/Android.mk
include $(commands_recovery_local_path)/minadbd/Android.mk
include $(commands_recovery_local_path)/mtdutils/Android.mk
include $(commands_recovery_local_path)/mmcutils/Android.mk
include $(commands_recovery_local_path)/tools/Android.mk
include $(commands_recovery_local_path)/edify/Android.mk
include $(commands_recovery_local_path)/updater/Android.mk
include $(commands_recovery_local_path)/applypatch/Android.mk
include $(commands_recovery_local_path)/utilities/Android.mk
include $(commands_recovery_local_path)/su/supersu/Android.mk
include $(commands_recovery_local_path)/voldclient/Android.mk
include $(commands_recovery_local_path)/device_images/Android.mk
include $(commands_recovery_local_path)/loki/Android.mk

ifdef PHILZ_TOUCH_RECOVERY
ifndef USE_PREBUILT_LIBTOUCH_GUI
include $(commands_recovery_local_path)/libtouch_gui/Android.mk
endif
endif

ifneq ($(BOARD_HAS_NO_FB2PNG),true)
    include $(commands_recovery_local_path)/fb2png/Android.mk
endif

ifneq ($(BOARD_USE_NTFS_3G),false)
    include $(commands_recovery_local_path)/ntfs-3g/Android.mk
endif

ifeq ($(BOARD_RECOVERY_USE_LIBTAR),true)
    include $(commands_recovery_local_path)/libtar/Android.mk
endif

ifeq ($(NO_AROMA_FILE_MANAGER),)
	include $(commands_recovery_local_path)/aromafm/Android.mk
endif
commands_recovery_local_path :=

endif
