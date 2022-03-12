#!/bin/bash -e

#! This is the main entry-point script for cccmk
#! It sets some key variables, and processes commandline arguments

if [ -z $debug ]
then debug=false
fi
if $debug
then set -x
fi

# set the initial values for important program variables

#! If set to `true`, then cccmk will display any `print_verbose` messages
verbose=$debug
#! If set to `true`, then cccmk will ignore whitespace characters when checking file diffs
ignore_spaces=false
#! If set to `true`, then cccmk will ignore any blank/empty lines when checking file diffs
ignore_blanks=false

#! The user-specified cccmk command
command=help
#! The user-specified arguments to the cccmk command
command_arg_name=
command_arg_path=



#! The installation path of cccmk
cccmk_install=~/.cccmk
#cccmk_install=~/.cccmk

#! The path which stores all cccmk data
if [ -z "$CCCMK_PATH" ]
then
	CCCMK_PATH="$cccmk_install"
	#print_warning "No value provided for CCCMK_PATH, using default: '$CCCMK_PATH'"
fi
if ! [ -d "$CCCMK_PATH" ]
then echo "cccmk error: Bad installation."
	echo "The CCCMK_PATH variable does not point to a valid folder: '$CCCMK_PATH'"
	exit 1
fi

#! The folder which stores cccmk source .sh scripts
cccmk_dir_scripts="scripts"
CCCMK_PATH_SCRIPTS="$CCCMK_PATH/$cccmk_dir_scripts"
if ! [ -d "$CCCMK_PATH_SCRIPTS" ]
then echo "cccmk error: Bad installation."
	echo "The CCCMK_PATH folder does not contain a '$cccmk_dir_scripts' folder: '$CCCMK_PATH_SCRIPTS'"
	exit 1
fi

#! The folder which stores cccmk template files for new projects
cccmk_dir_project="project"
CCCMK_PATH_PROJECT="$CCCMK_PATH/$cccmk_dir_project"
if ! [ -d "$CCCMK_PATH_PROJECT" ]
then echo "cccmk error: Bad installation."
	echo "The CCCMK_PATH folder does not contain a '$cccmk_dir_project' folder: '$CCCMK_PATH_PROJECT'"
	exit 1
fi



# set the fundamental cccmk variables

#! The version number of the currently installed cccmk
cccmk_version="`( cat "$cccmk_install/VERSION" )`"
#! The git revision of the currently installed cccmk
cccmk_git_rev="`( cd "$cccmk_install" ; git rev-parse HEAD )`"
#! The git repo URL from which to get any cccmk templates
cccmk_git_url="https://raw.githubusercontent.com/LexouDuck/libccc"
#! The git branch name/revision hash to use when doing a 'cccmk upgrade'
cccmk_upgrade=dev
#! The shell command (and arguments) used to perform and display file text diffs
cccmk_diffcmd="git --no-pager diff --no-index --color"
#cccmk_diffcmd="diff --color"
cccmk_diff_fancy()
{
	local args=""
	if $ignore_spaces
	then args="$args --ignore-space-change"
	fi
	if $ignore_blanks
	then args="$args --ignore-blank-lines"
	fi
	$cccmk_diffcmd $args "$1" "$2" || :
}
cccmk_diff_brief()
{
	local args=""
	if $ignore_spaces
	then args="$args --ignore-space-change"
	fi
	if $ignore_blanks
	then args="$args --ignore-blank-lines"
	fi
	diff -qrs -U 1000 $args "$1" "$2" \
	| awk \
	-v path_old="$1" \
	-v path_new="$2" \
	-f "$CCCMK_PATH_SCRIPTS/util.awk" \
	-f "$CCCMK_PATH_SCRIPTS/diff.awk"
}



# general shell utility functions
. $CCCMK_PATH_SCRIPTS/util.sh
# general shell user-prompting functions
. $CCCMK_PATH_SCRIPTS/prompt.bash
# cccmk help doc texts and functions
. $CCCMK_PATH_SCRIPTS/cccmk_help.sh



# check that necessary shell commands are installed and usable

# check the `diff` command
if ! diff --version > /dev/null
then print_error "cccmk requires the shell command 'diff' to be installed and accessible from the \$PATH."	; exit 1
fi
# check the `git` command
if ! git --version > /dev/null
then print_error "cccmk requires the shell command 'git' to be installed and accessible from the \$PATH."	; exit 1
fi
# check the `make` command
if ! make --version > /dev/null
then print_error "cccmk requires the shell command 'make' to be installed and accessible from the \$PATH."	; exit 1
fi



#! Parses program arguments, assessing which command is called, handling arg errors etc
parse_args()
{
	if [ $# -eq 0 ]
	then print_warning "No command/arguments given to cccmk, displaying help..."
	else while [ $# -gt 0 ]
	do
		if [ "`echo "$1" | cut -c1-1`" == "-" ]
		then # options (w/ leading dash)
		case "$1" in
			(-h|--help|help)        command="$1" ; show_help    ; exit 0 ;;
			(-v|--version|version)  command="$1" ; show_version ; exit 0 ;;
			(-V|--verbose)          verbose=true ;;
			(-w|--ignore-spaces)    ignore_spaces=true ;;
			(-W|--ignore-blanks)    ignore_blanks=true ;;
			(-*)
				print_failure "Unknown option: '$1' (try 'cccmk --help')"
				show_usage
				exit 1
				;;
		esac
		else # commands (no leading dash)
		case "$1" in
			(create)
				command="$1"
				print_verbose "parsed command: '$command'"
				if [ $# -le 1 ]
				then print_error "The 'create' command expects a <PROJECT_NAME> argument (try 'cccmk --help')"
					exit 1
				fi
				command_arg_name="$2"
				if [ $# -gt 2 ]
				then command_arg_path="$3" ; shift
				else command_arg_path="./$2"
				fi
				shift
				;;
			(migrate)
				command="$1"
				print_verbose "parsed command: '$command'"
				if [ $# -gt 1 ]
				then command_arg_path="$2" ; shift
				else command_arg_path="."
				fi
				;;
			(diff|update)
				command="$1"
				print_verbose "parsed command: '$command'"
				if [ $# -gt 1 ]
				then
					shift
					command_arg_path="$@"
					while [ $# -gt 1 ]
					do
						shift
					done
				fi
				;;
			(upgrade)
				command="$1"
				print_verbose "parsed command: '$command'"
				;;
			(*)
				print_failure "Invalid argument: '$1' (try 'cccmk --help')"
				show_usage
				exit 1
				;;
		esac
		fi
		shift # go to next argument
	done
	fi
	print_verbose "finished parsing args."
	print_verbose "verbose = $verbose"
	print_verbose "command = '$command'"
	print_verbose "command_arg_name = '$command_arg_name'"
	print_verbose "command_arg_path = '$command_arg_path'"
}

parse_args "$@"



# set the project configuration variables

#! The filepath of a project's project-tracker file
project_cccmkfile=".cccmk"

#! Parsed from the .cccmk file: The author of a project
project_author=
#! Parsed from the .cccmk file: The name of a project
project_name=
#! Parsed from the .cccmk file: The year of a project
project_year=
#! Parsed from the .cccmk file: The type (program/library) of a project
project_type=
#! Parsed from the .cccmk file: The cccmk commit revision
project_cccmk="dev"
#! Parsed from the .cccmk file: The filepath of a project's versioning info file
project_versionfile="VERSION"
#! Parsed from the .cccmk file: The filepath of a project's package dependency list file
project_packagefile="$project_mkpath/lists/packages.txt"
#! Parsed from the .cccmk file: The folders which are to be "fully tracked" by cccmk, if any
project_track_paths=""
#! Parsed from the .cccmk file: the list of project files to track with cccmk
project_track=



#! The list of absent files which are necessary for any project using cccmk
project_missing=

if ! [ -f "./$project_cccmkfile" ]
then print_warning "The current folder is not a valid cccmk project folder - missing '$project_cccmkfile'"
	project_missing="$project_missing\n- missing project tracker file: '$project_cccmkfile'"
else
	# parse the .cccmk file (by simply running it as an inline shell script)
	. "./$project_cccmkfile"
	print_verbose "parsed project_author:      '$project_author'"
	print_verbose "parsed project_name:        '$project_name'"
	print_verbose "parsed project_year:        '$project_year'"
	print_verbose "parsed project_lang:        '$project_lang'"
	print_verbose "parsed project_type:        '$project_type'"
	print_verbose "parsed project_cccmk:       '$project_cccmk'"
	print_verbose "parsed project_versionfile: '$project_versionfile'"
	print_verbose "parsed project_packagefile: '$project_packagefile'"
	print_verbose "parsed project_track_paths: '$project_track_paths'"
	print_verbose "parsed project_track:       '$project_track'"
fi

if [ -z "$project_versionfile" ]
then :
elif ! [ -f "./$project_versionfile" ]
then project_missing="$project_missing\n- missing versioning info file: '$project_versionfile'"
fi

if [ -z "$project_packagefile" ]
then :
elif ! [ -f "./$project_packagefile" ]
then project_missing="$project_missing\n- missing packages dependency list file: '$project_packagefile'"
fi

# display warning if current folder is missing any necessary project files
if ! [ -z "$project_missing" ]
then print_warning "The current cccmk project folder is missing important files:$project_missing"
fi



#! Takes in a template text file, and creates a text file from the given variable values
#! @param $1	inputfile (filepath): the template text file used to generate our final file
#! @param $2	outputfile [optional] (filepath): if not specified, inputfile is modified in-place
#! @param $3	variables  [optional] (string): the list of variable names and their values
#!          	Each key/value pair has an '=' equal, and they are separated with ';' semi-colons.
#!          	'foo=a; bar=b; baz=c;' is a valid example. If nothing is specified, cccmk project variables are used.
cccmk_template()
{
	local inputfile="$1"
	local outputfile="$2"
	local variables="$3"
	if [ -z "$variables" ]
	then variables="
		author=$project_author;
		name=$project_name;
		year=$project_year;
		lang=$project_lang;
		type=$project_type;
		cccmk=$project_cccmk;
		versionfile=$project_versionfile;
		packagefile=$project_packagefile;
		track_paths=$project_track_paths;
		track=$project_track;
		"
	fi
	if [ -z "$outputfile" ]
	then
		awk_inplace "$inputfile" \
		-v variables="$variables" \
		-f "$CCCMK_PATH_SCRIPTS/util.awk" \
		-f "$CCCMK_PATH_SCRIPTS/template-functions.awk" \
		-f "$CCCMK_PATH_SCRIPTS/template.awk"
	else
		awk \
		-v variables="$variables" \
		-f "$CCCMK_PATH_SCRIPTS/util.awk" \
		-f "$CCCMK_PATH_SCRIPTS/template-functions.awk" \
		-f "$CCCMK_PATH_SCRIPTS/template.awk" \
		"$inputfile" > "$outputfile"
		# preserve file permissions
		chmod "`file_getmode "$inputfile" `" "$outputfile"
	fi
}



# perform action, according to parsed arguments
case "$command" in
	help)    show_help    ;;
	version) show_version ;;
	create)  . $CCCMK_PATH_SCRIPTS/cccmk_create.sh  ;;
	migrate) . $CCCMK_PATH_SCRIPTS/cccmk_migrate.sh ;;
	diff)    . $CCCMK_PATH_SCRIPTS/cccmk_diff.sh    ;;
	update)  . $CCCMK_PATH_SCRIPTS/cccmk_update.sh  ;;
	upgrade) . $CCCMK_PATH_SCRIPTS/cccmk_upgrade.sh ;;
esac