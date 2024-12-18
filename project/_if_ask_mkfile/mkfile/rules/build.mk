#! This file holds C-specific rules to build a %[type]%



objs = ` cat "$(OBJSFILE)" | tr '\n' ' ' `

#! Path of the file which stores the list of compiled object files
OBJSFILE = $(OBJPATH)objs.txt

#! Derive list of compiled object files (.o) from list of srcs
OBJS := $(SRCS:$(SRCDIR)%.%[lang]%=$(OBJPATH)%.o)

#! Derive list of dependency files (.d) from list of srcs
DEPS := $(OBJS:%.o=%.d)

# here we add dependency library linking flags for each package
LDLIBS := $(LDLIBS) \
	$(foreach i,$(PACKAGES), $(PACKAGE_$(i)_LINK))

# here we add include header folders for each package
INCLUDES := $(INCLUDES) \
	$(foreach i,$(PACKAGES), -I$(PACKAGE_$(i)_INCLUDE))

#! Shell command used to copy over dependency libraries from ./lib into ./bin
#! @param	$(1)	The subdirectory within the ./bin target folder
bin_copylibs = \
	mkdir -p $(BINPATH)$(1) ; \
	$(foreach i,$(PACKAGES), \
		if [ $(PACKAGE_$(i)_LIBMODE) = "dynamic" ] ; then \
			for i in $(PACKAGE_$(i)_LINKDIR)*.$(LIBEXT_dynamic)* ; do \
				cp -Rp "$$i" $(BINPATH)$(1) || $(call print_warning,"No library files to copy from $(PACKAGE_$(i)_LINKDIR)*") ; \
			done ; \
		fi ; )

#! Shell command used to create symbolic links for version-named library binary
#! @param $(1)	path of the binary file (folder, relative to root-level Makefile)
#! @param $(2)	name of the binary file (without version number, and without file extension)
#! @param $(3)	file extension of the binary file
bin_symlinks = \
	cd $(1) \

%%if is(type,library)
ifeq ($(OSMODE),macos)
bin_symlinks += \
	&& mv     $(2).$(3)            $(2).$(VERSION).$(3) \
	&& ln -sf $(2).$(VERSION).$(3) $(2).$(VERSION_MAJOR).$(3) \
	&& ln -sf $(2).$(VERSION).$(3) $(2).$(3) \

endif
ifeq ($(OSMODE),linux)
bin_symlinks += \
	&& mv     $(2).$(3)            $(2).$(3).$(VERSION) \
	&& ln -sf $(2).$(3).$(VERSION) $(2).$(3).$(VERSION_MAJOR) \
	&& ln -sf $(2).$(3).$(VERSION) $(2).$(3) \

endif

%%end if


.PHONY:\
build #! Builds the %[type]%, with the default BUILDMODE (typically debug)
build: \
%%if is(type,program):$(BINPATH)$(NAME)
%%if is(type,library)
$(BINPATH)static/$(NAME_static) \
$(BINPATH)dynamic/$(NAME_dynamic) \
%%end if

.PHONY:\
build-debug #! Builds the %[type]%, in 'debug' mode (with debug flags and symbol-info)
build-debug:
	@$(MAKE) build BUILDMODE=debug

.PHONY:\
build-release #! Builds the %[type]%, in 'release' mode (with optimization flags)
build-release:
	@$(MAKE) build BUILDMODE=release



#! Generates the list of object files
$(OBJSFILE): $(SRCSFILE)
	@mkdir -p $(@D)
	@printf "" > $(OBJSFILE)
	$(foreach i,$(OBJS),	@printf "$(i)\n" >> $(OBJSFILE) $(C_NL))



%%if is(lang,cpp)
#! Compiles object files from C++ source files
$(OBJPATH)%.o : $(SRCDIR)%.cpp
	@mkdir -p $(@D)
	@printf "Compiling file: $@ -> "
	@$(CXX) -o $@ $(CXXFLAGS) $(CPPFLAGS) -MMD $(INCLUDES) -c $<
	@printf $(IO_GREEN)"OK!"$(IO_RESET)"\n"

%%end if
#! Compiles object files from C source files
$(OBJPATH)%.o : $(SRCDIR)%.c
	@mkdir -p $(@D)
	@printf "Compiling file: $@ -> "
	@$(CC) -o $@ $(CFLAGS) $(CPPFLAGS) -MMD $(INCLUDES) -c $<
	@printf $(IO_GREEN)"OK!"$(IO_RESET)"\n"



%%if is(type,program)
#! Compiles the project executable
$(BINPATH)$(NAME): $(OBJSFILE) $(OBJS)
	@rm -f $@
	@mkdir -p $(@D)
	@printf "Compiling program: $@ -> "
	@$(CC) -o $@ $(CFLAGS) $(LDFLAGS) $(call objs) $(LDLIBS)
	@printf $(IO_GREEN)"OK!"$(IO_RESET)"\n"
	@$(call bin_copylibs)
	@$(call bin_symlinks,$(BINPATH),$(NAME),)
%%end if
%%if is(type,library)
#! Builds the static-link library '.a' binary file for the current target platform
$(BINPATH)static/$(NAME_static): $(OBJSFILE) $(OBJS)
	@rm -f $@
	@mkdir -p $(@D)
	@printf "Compiling static library: $@ -> "
	@$(AR) $(ARFLAGS) $@ $(call objs)
	@$(RANLIB) $(RANLIB_FLAGS) $@ || $(call print_warning,"call to 'ranlib' command failed: $(RANLIB) $(RANLIB_FLAGS) $@")
	@printf $(IO_GREEN)"OK!"$(IO_RESET)"\n"
	@$(call bin_copylibs,static)
	@$(call bin_symlinks,$(BINPATH)static,$(NAME),$(LIBEXT_static))

#! Builds the dynamic-link library file(s) for the current target platform
$(BINPATH)dynamic/$(NAME_dynamic): $(OBJSFILE) $(OBJS)
	@rm -f $@
	@mkdir -p $(@D)
	@printf "Compiling dynamic library: $@ -> "
ifeq ($(OSMODE),other)
	@$(call print_warning,"Unknown platform: needs manual configuration.")
	@$(call print_warning,"You must manually configure the script to build a dynamic library")
endif
ifeq ($(OSMODE),windows)
	@$(CC) -shared -o $@ $(CFLAGS) $(LDFLAGS) $(call objs) $(LDLIBS) \
		-Wl,--output-def,$(NAME).def \
		-Wl,--out-implib,$(NAME).lib \
		-Wl,--export-all-symbols
	@cp -p $(NAME).def $(BINPATH)dynamic/
	@cp -p $(NAME).lib $(BINPATH)dynamic/
endif
ifeq ($(OSMODE),macos)
	@$(CC) -shared -o $@ $(CFLAGS) $(LDFLAGS) $(call objs) $(LDLIBS) \
		-install_name '@loader_path/$(NAME_dynamic)'
endif
ifeq ($(OSMODE),linux)
	@$(CC) -shared -o $@ $(CFLAGS) $(LDFLAGS) $(call objs) $(LDLIBS) \
		-Wl,-rpath='$$ORIGIN/'
endif
	@printf $(IO_GREEN)"OK!"$(IO_RESET)"\n"
	@$(call bin_copylibs,dynamic)
	@$(call bin_symlinks,$(BINPATH)dynamic,$(NAME),$(LIBEXT_dynamic))
%%end if



# The following line is for `.d` dependency file handling
-include $(DEPS)



.PHONY:\
mkdir-build #! Creates all the build folders in the ./bin folder (according to `OSMODES`)
mkdir-build:
	@$(call print_message,"Creating build folders...")
	$(foreach i,$(BUILDMODES),\
	$(foreach os,$(OSMODES),\
%%if is(type,library):	$(foreach libmode,$(LIBMODES),\
%%if is(type,library):	$(foreach cpu,$(CPUMODES),	@mkdir -p $(BINDIR)$(i)_$(os)_$(cpu)/$(libmode)$(C_NL)))))
%%if is(type,program):	$(foreach cpu,$(CPUMODES),	@mkdir -p $(BINDIR)$(i)_$(os)_$(cpu)$(C_NL))))



.PHONY:\
clean-build #! Deletes all intermediary build-related files
clean-build: \
clean-build-obj \
clean-build-dep \
clean-build-bin \
%%if is(type,program):clean-build-exe \
%%if is(type,library):clean-build-lib \

.PHONY:\
clean-build-obj #! Deletes all .o build object files, for the current TARGETDIR
clean-build-obj:
	@$(call print_message,"Deleting all .o files for target $(TARGETDIR)...")
	$(foreach i,$(OBJS),	@rm -f "$(i)" $(C_NL))

.PHONY:\
clean-build-dep #! Deletes all .d build dependency files, for the current TARGETDIR
clean-build-dep:
	@$(call print_message,"Deleting all .d files for target $(TARGETDIR)...")
	$(foreach i,$(DEPS),	@rm -f "$(i)" $(C_NL))

.PHONY:\
clean-build-bin #! Deletes all build binaries, for the current TARGETDIR
clean-build-bin:
%%if is(type,program)
	@$(call print_message,"Deleting binaries in '$(BINPATH)'...")
	@rm -f $(BINPATH)*
%%end if
%%if is(type,library)
	@$(call print_message,"Deleting binaries in '$(BINPATH)static'...")
	@rm -f $(BINPATH)static/*
	@$(call print_message,"Deleting binaries in '$(BINPATH)dynamic'...")
	@rm -f $(BINPATH)dynamic/*
%%end if

.PHONY:\
%%if is(type,program)
clean-build-exe #! Deletes the built program, for the current TARGETDIR
clean-build-exe:
	@$(call print_message,"Deleting program: $(BINPATH)$(NAME)")
	@rm -f $(BINPATH)$(NAME)
	@rm -f $(NAME)
%%end if
%%if is(type,library)
clean-build-lib #! Deletes the built library(ies), for the current TARGETDIR
clean-build-lib:
	@$(call print_message,"Deleting static library: $(BINPATH)static/$(NAME_static)")
	@rm -f $(BINPATH)static/$(NAME_static)
	@$(call print_message,"Deleting dynamic library: $(BINPATH)dynamic/$(NAME_dynamic)")
	@rm -f $(BINPATH)dynamic/$(NAME_dynamic)
%%end if



.PHONY:\
prereq-build #! Checks prerequisite installed tools to build a %[type]%
prereq-build:
	@-$(call check_prereq,'(build) C compiler: $(CC)',\
		$(CC) --version,\
		$(call install_prereq,$(CC)))
%%if is(type,library)
	@-$(call check_prereq,'(build) C archiver: $(AR)',\
		which $(AR),\
		$(call install_prereq,binutils))
	@-$(call check_prereq,'(build) C archive symbol table tool: $(RANLIB)',\
		which $(RANLIB),\
		$(call install_prereq,binutils))
%%end if
