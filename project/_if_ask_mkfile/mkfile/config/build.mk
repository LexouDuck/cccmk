#! This file holds the variables which configure the code compilation



%%if is(type,library)
#! GNU conventional variable: archiver program (for static libraries)
AR = ar
#! GNU conventional variable: archiver program options
ARFLAGS = \
	-r \
	-c \

#! GNU conventional variable: archive symbol table tool (for static libraries)
RANLIB = ranlib
#! GNU conventional variable: archive symbol table tool options
RANLIB_FLAGS = \



%%end if
%%if is(lang,cpp)
#! GNU conventional variable: C/C++ compiler options (given to both C and C++ compiler)
CPPFLAGS ?= \



#! GNU conventional variable: C++ compiler
CXX = $(CXX_OS)
#! C compiler platform-specific variable, according to $(OSMODE)
CXX_OS = $(CXX_OS_$(OSMODE))
CXX_OS_windows = $(if $(findstring 64,$(CPUMODE)),x86_64-w64-mingw32-g++,i686-w64-mingw32-g++)
CXX_OS_macos = clang++
CXX_OS_linux = g++
CXX_OS_other = cc



#! GNU conventional variable: C++ compiler options
CXXFLAGS = \
	-Wall \
	-Wextra \
	-std=%[langversion]% \
	$(CXXFLAGS_BUILDMODE) \
	$(CXXFLAGS_OS) \
	$(CXXFLAGS_EXTRA)

#! C++ compiler options which are specific to the current build mode, according to $(BUILDMODE)
CXXFLAGS_BUILDMODE = $(CXXFLAGS_BUILDMODE_$(BUILDMODE))
#! C++ compiler flags which are only present in "debug" build mode
CXXFLAGS_BUILDMODE_debug = \
	-g \
	-ggdb \
	-D DEBUG=1
#! C++ compiler flags which are only present in "release" build mode
CXXFLAGS_BUILDMODE_release = \
	-O3 \
	-D RELEASE=1

#! C++ compiler options which are platform-specific, according to $(OSMODE)
CXXFLAGS_OS = $(CXXFLAGS_OS_$(OSMODE))
CXXFLAGS_OS_windows = -D__USE_MINGW_ANSI_STDIO=1 # -fno-ms-compatibility
CXXFLAGS_OS_macos = 
CXXFLAGS_OS_linux = -fPIC
CXXFLAGS_OS_other = 
ifneq ($(findstring clang,$(CXX)),)
	CXXFLAGS_OS += -Wno-missing-braces
	CXXFLAGS_OS += -Wno-reserved-user-defined-literal
endif

#! This variable is intentionally empty, to specify additional C++ compiler options from the commandline
CXXFLAGS_EXTRA ?= \



%%end if
#! GNU conventional variable: C compiler
CC = $(CC_OS)
#! C compiler platform-specific variable, according to $(OSMODE)
CC_OS = $(CC_OS_$(OSMODE))
CC_OS_windows = $(if $(findstring 64,$(CPUMODE)),x86_64-w64-mingw32-gcc,i686-w64-mingw32-gcc)
CC_OS_macos = clang
CC_OS_linux = gcc
CC_OS_other = cc



#! GNU conventional variable: C compiler options
CFLAGS = \
	-Wall \
	-Wextra \
	-Winline \
	-Wpedantic \
	-Wstrict-prototypes \
	-Wmissing-prototypes \
	-Wold-style-definition \
	-fstrict-aliasing \
%%if is(lang,c):	-std=%[langversion]% \
	$(CFLAGS_BUILDMODE) \
	$(CFLAGS_OS) \
	$(CFLAGS_EXTRA)

#! C compiler options which are specific to the current build mode, according to $(BUILDMODE)
CFLAGS_BUILDMODE = $(CFLAGS_BUILDMODE_$(BUILDMODE))
#! C compiler flags which are only present in "debug" build mode
CFLAGS_BUILDMODE_debug = \
	-g \
	-ggdb \
	-D DEBUG=1
#! C compiler flags which are only present in "release" build mode
CFLAGS_BUILDMODE_release = \
	-O3 \
	-D RELEASE=1

#! C compiler options which are platform-specific, according to $(OSMODE)
CFLAGS_OS = $(CFLAGS_OS_$(OSMODE))
CFLAGS_OS_windows = -D__USE_MINGW_ANSI_STDIO=1 # -fno-ms-compatibility
CFLAGS_OS_macos = -Wno-language-extension-token
CFLAGS_OS_linux = -Wno-unused-result -fPIC
CFLAGS_OS_other = 
ifneq ($(findstring clang,$(CC)),)
	CFLAGS_OS += -Wno-missing-braces
endif

#! This variable is intentionally empty, to specify additional C compiler options from the commandline
CFLAGS_EXTRA ?= \
#	-flto \
#	-fanalyzer \
#	-fsanitize=address \
#	-fsanitize=thread \
#	-std=ansi -pedantic \
#	-D __NOSTD__=1 \

ifneq ($(findstring ++,$(CC)),)
CFLAGS_EXTRA += \
	-Wno-deprecated \
	-Wno-variadic-macros \
	-Wno-c99-extensions \
	-Wno-c++11-extensions \
	-Wno-c++17-extensions \
	-Wno-return-type-c-linkage \

endif



#! GNU conventional variable: C linker options
LDFLAGS = \
	$(LDFLAGS_BUILDMODE) \
	$(LDFLAGS_OS) \
	$(LDFLAGS_EXTRA)

#! C linker options which are specific to the current build mode, according to $(BUILDMODE)
LDFLAGS_BUILDMODE = $(LDFLAGS_BUILDMODE_$(BUILDMODE))
LDFLAGS_BUILDMODE_debug = 
LDFLAGS_BUILDMODE_release = 

#! C linker options which are platform-specific, according to $(OSMODE)
LDFLAGS_OS = $(LDFLAGS_OS_$(OSMODE))
LDFLAGS_OS_windows = 
LDFLAGS_OS_macos = 
LDFLAGS_OS_linux = 
LDFLAGS_OS_other = 
ifneq ($(findstring clang,$(CC)),)
%%if is(type,library)
	LDFLAGS_OS_macos += -current_version       $(VERSION)
	LDFLAGS_OS_macos += -compatibility_version $(VERSION)
%%end if
endif

#! This variable is intentionally empty, to specify additional C linker options from the commandline
LDFLAGS_EXTRA ?= \



#! GNU conventional variable: C libraries to link against
LDLIBS = \
	$(LDLIBS_BUILDMODE) \
	$(LDLIBS_OS) \
	$(LDLIBS_EXTRA)

#! Linked libraries which are specific to the current build mode, according to $(BUILDMODE)
LDLIBS_BUILDMODE = $(LDLIBS_BUILDMODE_$(BUILDMODE))
LDLIBS_BUILDMODE_debug = 
LDLIBS_BUILDMODE_release = 

#! Linked libraries which are platform-specific, according to $(OSMODE)
LDLIBS_OS = $(LDLIBS_OS_$(OSMODE))
LDLIBS_OS_windows = 
LDLIBS_OS_macos = 
LDLIBS_OS_linux = 
LDLIBS_OS_other = 
ifneq ($(findstring mingw,$(CC)),)
LDLIBS_OS += -L./ -static-libgcc
endif

#! This variable is intentionally empty, to specify additional linked libraries from the commandline
LDLIBS_EXTRA ?= \
# -L/usr/local/lib -ltsan \



#! GNU conventional variable: List of included folders, which store header code files
INCLUDES = \
	-I$(HDRDIR) \
	$(INCLUDES_BUILDMODE) \
	$(INCLUDES_OS) \
	$(INCLUDES_EXTRA)

#! Header directories which are specific to the current build mode, according to $(BUILDMODE)
INCLUDES_BUILDMODE = $(INCLUDES_BUILDMODE_$(BUILDMODE))
INCLUDES_BUILDMODE_debug = 
INCLUDES_BUILDMODE_release = 

#! Header directories which are platform-specific, according to $(OSMODE)
INCLUDES_OS = $(INCLUDES_OS_$(OSMODE))
INCLUDES_OS_windows = 
INCLUDES_OS_macos = 
INCLUDES_OS_linux = 
INCLUDES_OS_other = 

#! This variable is intentionally empty, to specify additional header directories from the commandline
INCLUDES_EXTRA ?= \
