#! This file holds rules to clean up the project folder, deleting generated files, etc



.PHONY:\
clean #! Deletes files generated by the `make all` default rule
clean: \
clean-build-obj \
clean-build-dep \
%%if is(type,library):clean-build-lib \
%%if is(type,program):clean-build-exe \
%%if tracked(_if_ask_mkfile/mkfile/_if_ask_testsuite/rules/build-tests.mk)
clean-tests-obj \
clean-tests-dep \
clean-tests-exe \
%%end if



.PHONY:\
clean-all #! Deletes every generated file/folder
clean-all: \
clean-build \
%%if tracked(_if_ask_mkfile/mkfile/_if_ask_testsuite/rules/build-tests.mk):clean-tests \
clean-obj \
clean-bin \
clean-log \
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
