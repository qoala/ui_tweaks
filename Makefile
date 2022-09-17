#
# To get started, copy makeconfig.example.mk as makeconfig.mk and fill in the appropriate paths.
#
# build (default): Build all the zips and kwads. "out/" is suitable for uploading to Steam.
# install: Copy mod files into a local installation of Invisible Inc
#

include makeconfig.mk

.PHONY: build

build: out/modinfo.txt out/scripts.zip out/gui.kwad out/images.kwad out/rrni_gui.kwad

install: build
	mkdir -p $(INSTALL_PATH)
	rm -f $(INSTALL_PATH)/*.kwad $(INSTALL_PATH)/*.zip
	cp out/modinfo.txt $(INSTALL_PATH)/
	cp out/scripts.zip $(INSTALL_PATH)/
	cp out/gui.kwad $(INSTALL_PATH)/
	cp out/images.kwad $(INSTALL_PATH)/
	cp out/rrni_gui.kwad $(INSTALL_PATH)/
ifneq ($(INSTALL_PATH2),)
	mkdir -p $(INSTALL_PATH2)
	rm -f $(INSTALL_PATH2)/*.kwad $(INSTALL_PATH2)/*.zip
	cp out/modinfo.txt $(INSTALL_PATH2)/
	cp out/scripts.zip $(INSTALL_PATH2)/
	cp out/gui.kwad $(INSTALL_PATH2)/
	cp out/images.kwad $(INSTALL_PATH2)/
	cp out/rrni_gui.kwad $(INSTALL_PATH2)/
endif

out/modinfo.txt: modinfo.txt
	mkdir -p out
	cp modinfo.txt out/modinfo.txt

out/rrni_gui.kwad: rrni_gui.kwad
	mkdir -p out
	cp rrni_gui.kwad out/rrni_gui.kwad

#
# kwads and contained files
#

# anims := $(patsubst %.anim.d,%.anim,$(shell find anims -type d -name "*.anim.d"))
#
# $(anims): %.anim: $(wildcard %.anim.d/*.xml $.anim.d/*.png)
# 	cd $*.anim.d && zip ../$(notdir $@) *.xml *.png

gui_files := $(wildcard gui/**/*.png)
images_files := $(wildcard images/**/*.png)

out/gui.kwad out/images.kwad: $(gui_files) $(images_files)
	mkdir -p out
	$(KWAD_BUILDER) -i build.lua -o out

#
# scripts
#

out/scripts.zip: $(shell find scripts -type f -name "*.lua")
	mkdir -p out
	cd scripts && zip -r ../$@ . -i '*.lua'
