#! This file holds rules to create a desktop GUI application, with relevant embedded metadata, icon, etc



#! The year for this application (used for copyright metadata)
APPYEAR := $(shell . .cccmk && echo $${project_year})
#! The author name for this application (used for copyright metadata)
APPSIGN := $(shell . .cccmk && echo $${project_author})
#! The full name of the application (with spaces, and any other strange characters)
APPNAME := $(NAME)
#! The short description of the application
APPDESC := 
#! The filepath of the icon file to associate with this application (ideally, a 512x512 .png image)
APPICON := 

#! The various sizes of application icons to produce from the source $(APPICON)
ICON_SIZES := \
16 \
32 \
48 \
64 \
128 \
256 \
512 \

#! The output filepath of the distributable application (platform-dependent)
APPDIST = $(BINDIR)$(OSMODE)/$(APPNAME)
#! The file which stores application metadata (platform-dependent)
APPFILE = $(BINDIR)$(OSMODE)/$(APPNAME)
#! The source template used to generate the platofmr-specific $(APPMETA) file
APPFILE_TEMPLATE = $(MKFILES_DIR)rules/app-info.$(OSMODE)



ifeq ($(OSMODE),)
_:=$(shell $(call print_error,"Unknown platform ($(OSMODE)), cannot embed application metadata"))



else ifeq ($(OSMODE),linux)
APPMETA = $(BINDIR)$(OSMODE)/.desktop
APPDIST = $(BINDIR)$(OSMODE)/$(APPNAME)
#! rule to create app bundle
$(APPDIST):
	@cp $(NAME) $(APPDIST)
#! rule to create app icon resource files
$(BINDIR)$(OSMODE)/.icons:
	@mkdir -p $@
	@for i in $(ICON_SIZES) ; do \
		folder='$@/$${i}x$${i}' ; \
		mkdir -p $$folder ; \
		magick convert $(APPICON) -scale $$i $$folder/$(NAME).png ; \
	done



else ifeq ($(OSMODE),macos)
APPMETA = $(BINDIR)$(OSMODE)/$(APPNAME).plist
APPDIST = $(BINDIR)$(OSMODE)/$(APPNAME).app
# 4-character code for legacy macintosh apps
APPCODE = $(shell echo "$(NAME)" | cut -c1-4 )
#! rule to create app bundle
$(APPDIST): $(APPFILE).icns
	@rm -rf $(APPDIST)
	@mkdir $(APPDIST)
	@mkdir $(APPDIST)/Contents
	@mkdir $(APPDIST)/Contents/MacOS
	@mkdir $(APPDIST)/Contents/Resources
	@cp $(NAME)              $(APPDIST)/Contents/MacOS/$(APPNAME)
	@mv $(APPMETA)           $(APPDIST)/Contents/Info.plist
	@cp $(APPFILE).icns      $(APPDIST)/Contents/Resources/icons.icns
	@echo "APPL$(APPCODE)" > $(APPDIST)/Contents/PkgInfo
	@rm -f $(APPMETA)
	@rm -rf $(APPFILE).icns
#! rule to create app icon resource file
$(APPFILE).icns: $(APPICON)
	@rm -rf   $(APPFILE).iconset
	@mkdir -p $(APPFILE).iconset
	@for i in $(ICON_SIZES) ; do \
		magick convert $(APPICON) -scale $${i} $(APPFILE).iconset/icon_$${i}x$${i}.png ; \
		half=$$(($$i / 2)) ; \
		cp  $(APPFILE).iconset/icon_$${i}x$${i}.png \
			$(APPFILE).iconset/icon_$${half}x$${half}@2x.png ; \
	done
	@iconutil -c icns -o $@ $(APPFILE).iconset
	@rm -rf $(APPFILE).iconset



else ifneq ($(filter $(OSMODE), win32 win64),)
APPMETA = $(BINDIR)$(OSMODE)/$(APPNAME).rc
APPDIST = $(BINDIR)$(OSMODE)/$(APPNAME).exe
#! rule to create app bundle
$(APPDIST): $(APPFILE).ico
	@mv $(APPFILE) $(APPMETA)
	@echo '0 ICON "$(APPFILE).ico"' > $(APPMETA).icon
	@windres $(APPMETA)      -O coff -o $(APPFILE).res
	@windres $(APPMETA).icon -O coff -o $(APPFILE).res.icon
	@$(MAKE) NAME='$(APPDIST)' LDFLAGS_EXTRA=' $(APPFILE).res $(APPFILE).icon.res '
	@rm -f $(APPMETA)
	@rm -f $(APPMETA).icon
	@rm -f $(APPFILE).res
	@rm -f $(APPFILE).res.icon
	@rm -f $(APPFILE).ico
#! rule to create app icon resource file
$(APPFILE).ico: $(APPICON)
	@mkdir -p $(TEMPDIR)
	@for i in $(ICON_SIZES) ; do \
		magick convert $(APPICON) -scale $${i} $(TEMPDIR)$${i}.png ; \
	done
	@magick convert $(foreach i,$(ICON_SIZES), $(TEMPDIR)$(i).png) $@
	@rm -rf $(TEMPDIR)



else
_:=$(shell $(call print_warning,"Unknown platform ($(OSMODE)), requires manual configuration"))
endif



# force app bundle to be re-created each time rule is called
.PHONY: $(APPDIST)



.PHONY:\
app #! creates a distributable GUI desktop application, with metadata and icon
app: build-release
	@if ! [ -d ~/.cccmk ]; then \
		$(call print_error,"You must install cccmk to use this rule (https://github.com/LexouDuck/cccmk)") ; \
	fi
	@$(call print_message,"Processing application metadata...")
	@awk \
		-v variables="\
			name=$(NAME);\
			appname=$(APPNAME);\
			description=$(APPDESC);\
			icon=$(APPICON);\
			year=$(APPYEAR);\
			author=$(APPSIGN);\
			version=$(VERSION);\
		" \
		-f ~/.cccmk/scripts/util.awk \
		-f ~/.cccmk/scripts/template-functions.awk \
		-f ~/.cccmk/scripts/template.awk \
		$(APPFILE_TEMPLATE) > $(APPMETA)
	@$(call print_message,"Creating application bundle...")
	@$(MAKE) $(APPDIST)
	@$(call print_success,"Created application bundle: $(APPDIST)")
