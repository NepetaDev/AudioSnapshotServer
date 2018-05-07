include $(THEOS)/makefiles/common.mk

export ARCHS = arm64 armv7
export TARGET = iphone:6.0:6.0
TWEAK_NAME = AudioSnapshotServer
$(TWEAK_NAME)_FILES = Tweak.xmi

include $(THEOS_MAKE_PATH)/tweak.mk