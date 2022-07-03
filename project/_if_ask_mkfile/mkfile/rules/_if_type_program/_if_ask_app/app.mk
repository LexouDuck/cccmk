#! This file holds rules to create a desktop GUI application, with relevant embedded metadata, icon, etc



#! The full name of the application (with spaces, and any other strange characters)
APPNAME := $(NAME)
#! The short description of the application
APPDESC := 
#! The filepath of the icon file to associate with this application (ideally, a 512x512 .png image)
APPICON := 
#! The year for this application (used for copyright metadata)
APPYEAR := $(shell . ./.cccmk && echo $${project_year})
#! The author name for this application (used for copyright metadata)
APPAUTHOR := $(shell . ./.cccmk && echo $${project_author})
#! The complete legal name of the application (this is where you would indicate copyright, if any)
APPLEGAL = $(APPNAME) v$(VERSION) - $(APPAUTHOR), $(APPYEAR)

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
APPDIST = $(BINPATH)$(APPNAME)
#! The file which stores application metadata (platform-dependent)
APPMETA = $(BINPATH)$(APPNAME).meta
#! A generic filename without an extension, used to do metadata operations to prepare app
APPFILE = $(BINPATH)$(APPNAME)



#! Shell command: ImageMagick command-line image editor toolchain
MAGICK := magick
#! Shell command: ImageMagick command-line options
MAGICK_FLAGS := 



ifeq ($(OSMODE),other)
_:=$(shell $(call print_warning,"Unknown platform ($(OSMODE)), requires manual configuration"))
endif



ifeq ($(OSMODE),linux)
APPDIST = $(BINPATH)$(APPNAME)
APPMETA = $(BINPATH)$(APPNAME).desktop
define APPMETADATA
[Desktop Entry]
Type=Application
Version=1.0
Name=$(APPNAME)
GenericName=$(APPLEGAL)
Comment=$(APPDESC)
Icon=$(NAME)
Path=$(abspath $(BINPATH))
Exec=$(abspath $(BINPATH)$(NAME))
Terminal=false
MimeType=
endef
export APPMETADATA
MAGICK = 
APPINSTALL_PREFIX = /usr/share# $(HOME)/.local/share
#! rule to create app bundle
$(APPDIST): $(APPMETA) $(BINPATH).icons
	@cp -p $(NAME) $(APPDIST)
	@desktop-file-validate $(APPMETA)
	@$(SUDO) desktop-file-install $(APPMETA) --dir=$(APPINSTALL_PREFIX)/applications
	@$(SUDO) cp -rp $(BINPATH).icons/*    $(APPINSTALL_PREFIX)/icons/hicolor/
	@$(SUDO) update-desktop-database $(APPINSTALL_PREFIX)/applications
#! rule to create metadata resource file
$(APPMETA):
	@mkdir -p $(@D)
	@echo "$${APPMETADATA}" > $(APPMETA)
#! rule to create app icon resource files
$(BINPATH).icons: $(APPICON)
	@mkdir -p $@
	@for i in $(ICON_SIZES) ; do \
		folder="$@/$${i}x$${i}/apps" ; \
		mkdir -p $$folder ; \
		$(MAGICK) convert $(APPICON) -scale $$i $$folder/$(NAME).png ; \
	done
endif



ifeq ($(OSMODE),macos)
APPDIST = $(BINPATH)$(APPNAME).app
APPMETA = $(BINPATH)$(APPNAME).plist
define APPMETADATA
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>      <string>English</string>
	<key>CFBundleName</key>                   <string>$(APPNAME)</string>
	<key>CFBundleExecutable</key>             <string>$(NAME)</string>
	<key>CFBundleGetInfoString</key>          <string>$(APPDESC)</string>
	<key>CFBundleIconFile</key>               <string>icons.icns</string>
	<key>CFBundleIdentifier</key>             <string>com.$(APPAUTHOR).$(NAME)</string>
	<key>CFBundleDocumentTypes</key>          <array></array>
	<key>CFBundleInfoDictionaryVersion</key>  <string>6.0</string>
	<key>CFBundlePackageType</key>            <string>APPL</string>
	<key>CFBundleShortVersionString</key>     <string>$(VERSION)</string>
	<key>CFBundleSignature</key>              <string>$(NAME)</string>
	<key>CFBundleVersion</key>                <string>$(VERSION)</string>
	<key>NSHumanReadableCopyright</key>       <string>$(APPLEGAL)</string>
	<key>LSMinimumSystemVersion</key>         <string>10</string>
</dict>
</plist>
endef
export APPMETADATA
# 4-character code for legacy macintosh apps
APPCODE = $(shell echo "$(NAME)" | cut -c1-4 )
#! rule to create app bundle
$(APPDIST): $(APPMETA) $(APPFILE).icns
	@rm -rf $(APPDIST)
	@mkdir $(APPDIST)
	@mkdir $(APPDIST)/Contents
	@mkdir $(APPDIST)/Contents/MacOS
	@mkdir $(APPDIST)/Contents/Resources
	@libs="`find $(BINPATH) -maxdepth 1 -name '*.framework' `" ; if ! [ -z "$${libs}" ] ; then cp -prf $${libs} $(APPDIST)/Contents/MacOS/ ; fi
	@libs="`find $(BINPATH) -maxdepth 1 -name '*.dylib'     `" ; if ! [ -z "$${libs}" ] ; then cp -prf $${libs} $(APPDIST)/Contents/MacOS/ ; fi
	@cp -p $(NAME)            $(APPDIST)/Contents/MacOS/$(NAME)
	@mv $(APPFILE).icns       $(APPDIST)/Contents/Resources/icons.icns
	@mv $(APPMETA)            $(APPDIST)/Contents/Info.plist
	@echo "APPL$(APPCODE)"  > $(APPDIST)/Contents/PkgInfo
#! rule to create metadata resource file
$(APPMETA):
	@mkdir -p $(@D)
	@echo "$${APPMETADATA}" > $(APPMETA)
#! rule to create app icon resource file
$(APPFILE).icns: $(APPICON)
	@mkdir -p $(APPFILE).iconset
	@for i in $(ICON_SIZES) ; do \
		$(MAGICK) convert $(APPICON) -scale $${i} $(APPFILE).iconset/icon_$${i}x$${i}.png ; \
		half=$$(($$i / 2)) ; \
		cp  $(APPFILE).iconset/icon_$${i}x$${i}.png \
			$(APPFILE).iconset/icon_$${half}x$${half}@2x.png ; \
	done
	@iconutil -c icns -o $@ $(APPFILE).iconset
	@rm -rf $(APPFILE).iconset
endif



ifeq ($(OSMODE),windows)
APPDIST = $(BINPATH)$(APPNAME).exe
APPMETA = $(BINPATH)$(APPNAME).rc
define APPMETADATA
1 VERSIONINFO
FILEVERSION     1,0,0,0
PRODUCTVERSION  1,0,0,0
BEGIN
	BLOCK "StringFileInfo"
	BEGIN
		BLOCK "040904E4"
		BEGIN
			VALUE "CompanyName",      "$(APPNAME)"
			VALUE "FileDescription",  "$(APPDESC)"
			VALUE "FileVersion",      "$(VERSION)"
			VALUE "InternalName",     "$(NAME)"
			VALUE "LegalCopyright",   "$(APPLEGAL)"
			VALUE "OriginalFilename", "$(NAME).exe"
			VALUE "ProductName",      "$(APPNAME)"
			VALUE "ProductVersion",   "$(VERSION)"
		END
	END
	BLOCK "VarFileInfo"
	BEGIN
		VALUE "Translation", 0x0409, 1252
	END
END
endef
export APPMETADATA
#! rule to create app bundle
$(APPDIST): $(APPMETA) $(APPFILE).ico
	@echo '0 ICON "$(APPFILE).ico"' > $(APPMETA).icon
	@windres $(APPMETA)      -O coff -o $(APPFILE).res
	@windres $(APPMETA).icon -O coff -o $(APPFILE).res.icon
	@$(MAKE) NAME='$(APPDIST)' LDFLAGS_EXTRA=' $(APPFILE).res $(APPFILE).icon.res '
	@rm -f $(APPMETA)
	@rm -f $(APPMETA).icon
	@rm -f $(APPFILE).res
	@rm -f $(APPFILE).res.icon
	@rm -f $(APPFILE).ico
#! rule to create metadata resource file
$(APPMETA):
	@mkdir -p $(@D)
	@echo "$${APPMETADATA}" > $(APPMETA)
#! rule to create app icon resource file
$(APPFILE).ico: $(APPICON)
	@mkdir -p $(TEMPDIR)
	@for i in $(ICON_SIZES) ; do \
		$(MAGICK) convert $(APPICON) -scale $${i} $(TEMPDIR)$${i}.png ; \
	done
	@$(MAGICK) convert $(foreach i,$(ICON_SIZES), $(TEMPDIR)$(i).png) $@
	@rm -rf $(TEMPDIR)
endif



# force app bundle to be re-created each time rule is called
.PHONY: $(APPDIST)



.PHONY:\
app #! creates a distributable GUI desktop application, with metadata and icon
app: BUILDMODE=release
app: $(NAME)
	@if ! [ -d ~/.cccmk ]; then \
		$(call print_error,"You must install cccmk to use this rule (https://github.com/LexouDuck/cccmk)") ; \
	fi
	@$(call print_message,"Processing application metadata...")
	@$(MAKE) $(APPDIST)
	@$(call print_success,"Created application bundle: $(APPDIST)")
