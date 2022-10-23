#! This file stores the main/default targets of the build system



.PHONY:\
all #! Builds all targets (this is the default rule)
all:
	$(foreach i,$(BUILDMODES),	@$(MAKE) BUILDMODE=$(i) build)



.PHONY:\
re #! Deletes all generated files and rebuilds `all`
re: \
clean \
all \



.PHONY:\
setup #! Performs initial setup steps for the project
setup: \
%%if tracked(_if_ask_mkfile/mkfile/rules/init.mk)    :init \
%%if tracked(_if_ask_mkfile/mkfile/rules/version.mk) :version \
%%if tracked(_if_ask_mkfile/mkfile/rules/prereq.mk)  :prereq \
%%if tracked(_if_ask_mkfile/mkfile/rules/packages.mk):packages \
