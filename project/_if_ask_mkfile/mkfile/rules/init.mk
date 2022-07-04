#! This file holds rules which perform some initial project/repo setup



.PHONY:\
init #! Performs initial project setup (should be executed once, after cloning the repo)
init:
	@$(call print_message,"Setting up project...")
%%if tracked(_if_ask_mkfile/mkfile/rules/packages.mk)               :	@mkdir -p $(LIBDIR)
%%if tracked(_if_ask_mkfile/mkfile/rules/_if_multiselect/doc.mk)    :	@mkdir -p $(DOCDIR)
%%if tracked(_if_ask_mkfile/mkfile/_if_ask_testsuite/rules/test.mk) :	@mkdir -p $(TESTDIR)
%%if tracked(.githooks/)                                            :	@mkdir -p $(GITHOOKSDIR)
%%if tracked(_if_ask_mkfile/mkfile/rules/lists.mk)                  :	@mkdir -p $(LISTSDIR)
	@$(GIT) submodule update --init --recursive
	@$(GIT) config submodule.recurse true
%%if tracked(.githooks/)
	@$(GIT) config core.hooksPath $(GITHOOKSDIR)
%%end if

# TODO 'configure' rule, for easier cross-platform setup ?
