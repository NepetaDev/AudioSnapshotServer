include $(THEOS)/makefiles/common.mk

export ARCHS = arm64 armv7
export TARGET = iphone::
TWEAK_NAME = AudioSnapshotServer
$(TWEAK_NAME)_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk