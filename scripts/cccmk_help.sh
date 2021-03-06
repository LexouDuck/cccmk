#!/bin/sh -e



#! The program version number
cccmk_version=0.1
#! The list of accepted commands
cccmk_commands='
help
version
create
migrate
diff
update
upgrade
'

cccmk_doc_args_help='cccmk [<OPTIONS>...] help'
cccmk_doc_text_help='
    Displays this brief help message (same as the -h/--help option).
'
cccmk_doc_args_version='cccmk [<OPTIONS>...] version'
cccmk_doc_text_version='
    Displays the cccmk version number info (same as the -v/--version option).
'
cccmk_doc_args_create='cccmk [<OPTIONS>...] create <PROJECT_NAME> [<PROJECT_DIR>]'
cccmk_doc_text_create='
    Creates a new project, filling the newly created project with various files,
    prompting the user to specify which mkfile scripts/rules they would like to use.
    - <PROJECT_NAME> is the name to give to the project.
    - <PROJECT_DIR> (optional) is the folder in which to create the project.
      If not specified, the new project folder will be created in the current folder,
      and this newly created project folder will be named "<PROJECT_NAME>".
'
cccmk_doc_args_migrate='cccmk [<OPTIONS>...] migrate [<PROJECT_DIR>]'
cccmk_doc_text_migrate='
    Converts an already-existing project (with a makefile) to have it use cccmk.
    - <PROJECT_DIR> (optional) is the project folder which should migrate to using cccmk.
      If not specified, the project folder to check is assumed to be "./", the current dir.
'
cccmk_doc_args_diff='cccmk [<OPTIONS>...] diff [<PATH>...]'
cccmk_doc_text_diff='
    Checks for differences between the given project tracked files and the template files.
    Can be only successfully be run from a valid cccmk project folder.
    - <PATH> (optional) is the filepath of one or more tracked files to diff-check.
      If a path to a folder is given, then any files inside it will be recursively included.
      If no path is specfied, then all of the project tracked files will be diff-checked.
'
cccmk_doc_args_update='cccmk [<OPTIONS>...] update [<PATH>...]'
cccmk_doc_text_update='
    Overwrites the given file with the latest cccmk template equivalent.
    Can be only successfully be run from a valid cccmk project folder.
    - <PATH> (optional) is the filepath of one or more tracked files to update.
      If a path to a folder is given, then any files inside it will be recursively included.
      If no path is specfied, then all of the project tracked files will be updated.
'
cccmk_doc_args_upgrade='cccmk [<OPTIONS>...] upgrade'
cccmk_doc_text_upgrade='
    Updates your local cccmk installation, by fetching new files from the latest version.
    Since the cccmk installation process uses a "git clone" of the official repository,
    updating cccmk itself is really just a simple "git pull" operation.
'



#! The list of accepted option flags (single-char short form)
cccmk_options='
h
v
V
w
W
'
cccmk_doc_flag_h='-h, --help           If provided, display this brief help message and exit.'
cccmk_doc_flag_v='-v, --version        If provided, display the cccmk version number info and exit.'
cccmk_doc_flag_V='-V, --verbose        If provided, show additional log messages for detailed info/debugging.'
cccmk_doc_flag_w='-w, --ignore-spaces  If provided, ignore any whitespace characters when checking file diffs.'
cccmk_doc_flag_W='-W, --ignore-blanks  If provided, ignore any blank or empty lines when checking file diffs.'



#! The list of possible valid project types
cccmk_project_types='
program
library
'



#! Displays program help
show_help()
{
	local line=""
	echo 'USAGE:'
	for i in $cccmk_commands
	do
		line="cccmk_doc_args_$i" ; echo "    ${!line}"
	done
	echo ''
	echo 'OPTIONS:'
	echo '    Here is the list of accepted options, both in "-c" short form, and "--string" long form'
	for i in $cccmk_options
	do
		line="cccmk_doc_flag_$i" ; echo "    ${!line}"
	done
	echo ''
	echo 'COMMANDS:'
	for i in $cccmk_commands
	do
		line="cccmk_doc_args_$i" ; printf "  \$ ${!line}"
		line="cccmk_doc_text_$i" ; printf  "    ${!line}\n"
	done
	echo ''
}



#! Displays brief program usage summary
show_usage()
{
	local options=""
	for i in $cccmk_options
	do options="$options|-$i"
	done
	options="`echo "$options" | cut -c2- `"
	echo "usage: cccmk [$options] <command> [<args>...]"
}



#! Displays program version
show_version()
{
	echo "cccmk - version $cccmk_version"
}
