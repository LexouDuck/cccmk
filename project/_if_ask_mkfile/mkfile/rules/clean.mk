#! This file holds rules to clean up the project folder, deleting generated files, etc



.PHONY:\
clean #! Deletes files generated by the `make all` default rule
clean:
	$(foreach i,$(BUILDMODES),	@$(MAKE) BUILDMODE=$(i) clean-build $(C_NL))
%%if tracked(_if_ask_mkfile/mkfile/_if_ask_testsuite/rules/build-tests.mk)
	$(foreach i,$(BUILDMODES),	@$(MAKE) BUILDMODE=$(i) clean-tests $(C_NL))
%%end if



.PHONY:\
clean-all #! Deletes every generated file/folder
clean-all: \
clean-obj \
clean-bin \
clean-log \
%%if tracked(_if_ask_mkfile/mkfile/rules/dist.mk):clean-dist \



.PHONY:\
clean-full #! Deletes every generated file/folder (even files checked in to the repo !!!)
clean-full: \
clean-obj \
clean-bin \
clean-log \
%%if tracked(_if_ask_mkfile/mkfile/rules/dist.mk):clean-dist \
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/doc.mk):clean-doc \
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/coverage.mk):clean-coverage \



.PHONY:\
clean-obj #! Deletes the ./obj folder
clean-obj:
	@$(call print_message,"Deleting the $(OBJDIR) folder...")
	@rm -rf $(OBJDIR)

.PHONY:\
clean-bin #! Deletes the ./bin folder
clean-bin:
	@$(call print_message,"Deleting the $(BINDIR) folder...")
	@rm -rf $(BINDIR)

.PHONY:\
clean-log #! Deletes the ./log folder
clean-log:
	@$(call print_message,"Deleting the $(LOGDIR) folder...")
	@rm -rf $(LOGDIR)
