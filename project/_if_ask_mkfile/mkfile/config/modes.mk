#! This file holds the default values and logic for project build configuration variables



#! Define all possible build modes
BUILDMODES = \
	debug	\
	release	\
# if the BUILDMODE variable has no value, give it a default value
ifeq ($(strip $(BUILDMODE)),)
	BUILDMODE=debug
else ifeq ($(BUILDMODE),debug)
else ifeq ($(BUILDMODE),release)
else
$(error Invalid value for BUILDMODE, should be `debug` or `release`)
endif



#! Define all possible library-linking modes
LIBMODES = \
	static	\
	dynamic	\
# if the LIBMODE variable has no value, give it a default value
ifeq ($(strip $(LIBMODE)),)
	LIBMODE=static
else ifeq ($(LIBMODE),static)
else ifeq ($(LIBMODE),dynamic)
else
$(error Invalid value for LIBMODE, should be `static` or `dynamic`)
endif

%%if is(type,library)
#! Define build target name for library, according to current $(LIBMODE)
NAME_LIBMODE = $(NAME_$(LIBMODE))
#! Define build target name for static library with appropriate file extensions
NAME_static = $(NAME).$(LIBEXT_static)
#! Define build target name for dynamic library with appropriate file extensions
NAME_dynamic = $(NAME).$(LIBEXT_dynamic)

%%end if


#! Define all possible supported target platforms/operating systems
OSMODES = \
	windows	\
	macos	\
	linux	\
	other	\
# if the OSMODE variable has no value, give it a default value based on the current platform
ifeq ($(strip $(OSMODE)),)
	OSMODE = other
	ifeq ($(OS),Windows_NT)
		OSMODE := windows
	else
		UNAME_S := $(shell uname -s)
		ifeq ($(UNAME_S),Linux)
			OSMODE := linux
		endif
		ifeq ($(UNAME_S),Darwin)
			OSMODE := macos
		endif
	endif
	ifeq ($(OSMODE),other)
	_:=$(call print_warning,"Could not estimate the current target platform, defaulting to 'OSMODE = other'...")
	endif
endif



#! Define all possible supported target ASM/CPU architectures
CPUMODES = \
	wasm-32	\
	wasm-64	\
	x86-32	\
	x86-64	\
	arm8-32	\
	arm8-64	\
	arm7-32	\
	arm7-64	\
	arm6-32	\
	arm6-64	\
	ppc-32	\
	ppc-64	\
	s390-32	\
	s390-64	\
	hppa-32	\
	hppa-64	\
	mips-32	\
	mips-64	\
	sparc-32\
	sparc-64\
	other	\
# if the CPUMODE variable has no value, give it a default value based on the current CPU architecture
ifeq ($(strip $(CPUMODE)),)
	UNAME_M := $(shell uname -m)
	UNAME_P := $(shell uname -p)
	CPUMODE = other
	ifdef __EMSCRIPTEN__
		CPUMODE := wasm-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
	else
		ifneq ($(findstring 86, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := x86-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
		ifneq ($(findstring amd, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := x86-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
		ifneq ($(findstring ia64, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := x86-64
		endif
		ifneq ($(findstring x64, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := x86-64
		endif
		ifneq ($(findstring arm, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := arm8-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
		ifneq ($(findstring armv6, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := arm6-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
		ifneq ($(findstring armv7, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := arm7-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
		ifneq ($(findstring aarch64, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := arm8-64
		endif
		ifneq ($(findstring ppc, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := ppc-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
		ifneq ($(findstring powerpc, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := ppc-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
		ifneq ($(findstring s390, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := s390-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
		ifneq ($(findstring s390x, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := s390-64
		endif
		ifneq ($(findstring parisc, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := hppa-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
		ifneq ($(findstring 9000/, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := hppa-64
		endif
		ifneq ($(findstring mips, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := mips-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
		ifneq ($(findstring sparc, $(UNAME_M) $(UNAME_P)),)
			CPUMODE := sparc-$(if $(findstring 64, $(UNAME_M) $(UNAME_P)),64,32)
		endif
	endif
	ifeq ($(OSMODE),other)
	_:=$(call print_warning,"Could not estimate the current target CPU architecture, defaulting to 'CPUMODE = other'...")
	endif
endif



#! The file extension used for static library files
LIBEXT_static=a

#! The file extension used for dynamic library files
LIBEXT_dynamic=
ifeq ($(OSMODE),other)
	LIBEXT_dynamic=
else ifeq ($(OSMODE),win32)
	LIBEXT_dynamic=dll
else ifeq ($(OSMODE),win64)
	LIBEXT_dynamic=dll
else ifeq ($(OSMODE),linux)
	LIBEXT_dynamic=so
else ifeq ($(OSMODE),macos)
	LIBEXT_dynamic=dylib
else
$(error Unsupported platform: you must configure the dynamic library file extension your machine uses)
endif
