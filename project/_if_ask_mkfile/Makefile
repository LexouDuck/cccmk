#! This is the root-level Makefile, which includes all the others



# NOTE: the two following variables are to stay at the very top of this Makefile and never move

#! The complete absolute path of the root-level makefile
MKFILE_PATH := "$(abspath $(lastword $(MAKEFILE_LIST)))"
#! The directory of the root-level makefile
CURRENT_DIR := $(patsubst %/,%,$(dir $(MKFILE_PATH)))
#! The sub-directory in which makefile scripts are stored
MKFILES_DIR := ./mkfile/



#######################################
#          Project variables          #
#######################################

#! Output filename for the %[type]%
NAME = %[name]%
%%if tracked(_if_ask_mkfile/mkfile/_if_ask_testsuite/rules/test.mk)

#! Output filename for the test suite program
NAME_TEST = %[name]%-test
%%end if



#######################################
#      Project folder structure       #
#######################################

# repository folders

#! The directory for header code files (stores `.h` files)
HDRDIR = ./hdr/
#! The directory for source code files (stores `.c` files)
SRCDIR = ./src/
#! The directory for dependency library files (stores libs - static:`.a` or dynamic:`.dll`/`.dylib`/`.so`)
LIBDIR = ./lib/
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/doc.mk)
#! The directory for documentation (stores config and scripts to generate doc)
DOCDIR = ./doc/
%%end if
%%if tracked(_if_ask_mkfile/mkfile/_if_ask_testsuite/rules/test.mk)
#! The directory for testing programs (stores source/header code for the various testing programs)
TESTDIR = ./test/
%%end if
%%if tracked(.githooks/)
#! The directory for git hooks scripts
GITHOOKSDIR = ./.githooks/
%%end if
%%if tracked(_if_ask_mkfile/mkfile/rules/lists.mk)
#! The directory for important list files (source files, packages)
LISTSDIR = $(MKFILES_DIR)lists/
%%end if

# generated folders

#! The name of the subfolder for the current compilation target
TARGETDIR = $(BUILDMODE)_$(OSMODE)_$(CPUMODE)

#! The directory for compiled object files (stores `.o` and `.d` files)
OBJDIR = ./obj/
OBJPATH = $(OBJDIR)$(TARGETDIR)/
#! The directory for built binary files (stores programs/libraries built by this project)
BINDIR = ./bin/
BINPATH = $(BINDIR)$(TARGETDIR)/
#! The directory for output logs (stores `.txt` outputs of the test suite program)
LOGDIR = ./log/
LOGPATH = $(LOGDIR)$(TARGETDIR)/
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/coverage.mk)
#! The directory for test-suite code-coverage output reports
COVDIR = $(LOGDIR)coverage/
COVPATH = $(COVDIR)$(TARGETDIR)/
%%end if
#! The directory for distribution archives (stores `.zip` distributable builds)
DISTDIR = ./dist/
#! The directory for temporary (can be used for several things - should always be deleted after use)
TEMPDIR = ./temp/
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/lint.mk)
#! The directory for linter/static analyzer output logs (stores warnings logs)
LINTDIR = $(LOGDIR)lint/
%%end if



#######################################
#     Included Makefile Variables     #
#######################################

# general variables
include $(MKFILES_DIR)utils/make.mk
include $(MKFILES_DIR)utils/shell.mk
include $(MKFILES_DIR)utils/prereq.mk
include $(MKFILES_DIR)utils/print.mk
include $(MKFILES_DIR)utils/ansi.mk
include $(MKFILES_DIR)utils/ext.mk

# project-specific variables
include $(MKFILES_DIR)config/modes.mk
include $(MKFILES_DIR)config/build.mk
%%if tracked(_if_ask_mkfile/mkfile/_if_ask_testsuite/rules/build-tests.mk):include $(MKFILES_DIR)config/build-tests.mk
include $(MKFILES_DIR)config/install.mk



# parse any .env files, to override variables
ifneq ($(wildcard .env),)
$(shell $(call print_message,"Sourcing local '.env' file..."))
$(shell sh ./.env)
endif



#######################################
#      Included Makefile Rules        #
#######################################

# project-specific rules
include $(MKFILES_DIR)rules/all.mk
include $(MKFILES_DIR)rules/init.mk
include $(MKFILES_DIR)rules/prereq.mk
include $(MKFILES_DIR)rules/version.mk
include $(MKFILES_DIR)rules/packages.mk

include $(MKFILES_DIR)rules/lists.mk
include $(MKFILES_DIR)rules/build.mk
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_type_program/_if_ask_app/app.mk):include $(MKFILES_DIR)rules/app.mk
include $(MKFILES_DIR)rules/install.mk
include $(MKFILES_DIR)rules/dist.mk
include $(MKFILES_DIR)rules/clean.mk

%%if tracked(_if_ask_mkfile/mkfile/_if_ask_testsuite/rules/lists-tests.mk):include $(MKFILES_DIR)rules/lists-tests.mk
%%if tracked(_if_ask_mkfile/mkfile/_if_ask_testsuite/rules/build-tests.mk):include $(MKFILES_DIR)rules/build-tests.mk
%%if tracked(_if_ask_mkfile/mkfile/_if_ask_testsuite/rules/test.mk)       :include $(MKFILES_DIR)rules/test.mk
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/coverage.mk)     :include $(MKFILES_DIR)rules/coverage.mk
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/debugging.mk)    :include $(MKFILES_DIR)rules/debugging.mk
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/format.mk)       :include $(MKFILES_DIR)rules/format.mk
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/lint.mk)         :include $(MKFILES_DIR)rules/lint.mk
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/doc.mk)          :include $(MKFILES_DIR)rules/doc.mk
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/doc-help.mk)     :include $(MKFILES_DIR)rules/doc-help.mk

# general rules
include $(MKFILES_DIR)utils/refactor.mk
include $(MKFILES_DIR)utils/help.mk
