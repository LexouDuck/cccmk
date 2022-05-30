#! This file holds certain utility variables for interacting with a UNIX shell



#! This allows us to use 'sudo' for certain operations while remaining cross-platform
ifeq ($(OS),Windows_NT)
	SUDO =
else
	SUDO = sudo
endif



#! This cross-platform function can be used to kill a running process via its name
ifeq ($(OS),Windows_NT)
kill = taskkill -F -IM $(1)
else
kill = sudo pkill $(1)
endif



#! Shell command used to run a program in a cross-platform manner
run = ./$(1)



#! Shell command used to run a program as a background service
ifeq ($(OS),Windows_NT)
daemon = cygstart --hide $(1)
else
daemon = $(1) &
endif
