TARGET = iphone:clang:latest:18.0
ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = M7MD

M7MD_FRAMEWORKS = IOKit UIKit Foundation Security QuartzCore CoreGraphics CoreText AVFoundation Accelerate GLKit SystemConfiguration GameController Metal MetalKit JRMemory
M7MD_CFLAGS = -I/opt/theos/include -I. -Iimgui8 -F. -w -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value
M7MD_CCFLAGS = -w -std=gnu++14 -fno-rtti -fno-exceptions -DNDEBUG -Wno-module-import-in-extern-c -I. -Iimgui8 -F.
M7MD_LDFLAGS = -F. -framework JRMemory

M7MD_FILES = \
	Tweak.mm \
	MenuOverlay.mm \
	Dumped_Offsets.cpp \
	$(wildcard imgui8/*.mm) \
	$(wildcard imgui8/*.cpp) \
	$(wildcard Menux/*.mm) \
	$(wildcard View/*.mm) \
	$(wildcard View/*.m) \
	$(wildcard CustomView/*.m) \
	$(wildcard utils/*.cpp) \
	$(wildcard utils/*.m) \
	$(wildcard ESP/*.mm)

include $(THEOS_MAKE_PATH)/tweak.mk
