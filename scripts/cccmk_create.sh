#!/bin/sh -e

#! Copies over files from a source directory to the output directory, for creating a project
project_template_copy()
{
	local srcpath="$1"
	local outpath="$2"
	local filename="$3"

	# skip any project template helper scripts
	if [ "$filename" = ".cccmk" ]
	then continue
	fi
	# if no value was provided to the 'output_filename' variable, then use the source filename
	if [ -z "$output_filename" ]
	then output_filename="$filename"
	fi
	# copy source template file over to output folder
	print_verbose "copying template file: '$srcpath/$filename' -> '$outpath/$output_filename'"
	cp -p "$srcdir/$srcpath/$filename" "$outdir/$outpath/$output_filename"
	# update the .cccmk project tracker file (only if path is not in an '_untracked' folder)
	if echo "$srcpath" | grep -q '_untracked'
	then print_verbose "file '$outpath/$output_filename' will not be tracked in the $project_cccmkfile file."
	else
		echo "$rev"":""$srcpath/$filename"":""$outpath/$output_filename" \
		| awk '{ gsub(/\.\//, ""); print; }' \
		>> "$project_cccmkfile"
	fi
	output_filename=""
}

#! Recursive function used to copy over template files from the `cccmk/project` folder
project_template_copy_recurse()
{
	local srcdir="$1"
	local outdir="$2"
	local dir="$3"
	local dest="$4"
	if [ -z "$dest" ]
	then dest="$dir"
	fi
	local rev="`( cd "$cccmk_install" && git rev-parse HEAD )`"
	# create destination folder
	mkdir -p "$outdir/$dest"
	# copy over all regular files
	for i in `list_onlyfiles "$srcdir/$dir"`
	do project_template_copy "$dir" "$dest" "$i"
	done
	# iterate over all subfolders, and check '_if_*' folders to conditionally copy certain files
	for subdir in `list_subfolders "$srcdir/$dir"`
	do
		case "$subdir" in
			# prompt the user to select one out of several files
			_if_select*)
				proposed_files=`ls "$srcdir/$dir/$subdir/" | sort --ignore-case | xargs `
				selected_file=
				prompt_message=
				prompt_default=
				descriptions=
				if [ -f "$srcdir/$dir/$subdir/.cccmk" ]
				then  . "$srcdir/$dir/$subdir/.cccmk"
				else prompt_message="Select the one file you wish to include in your project:"
				fi
				printf "$io_cyan""$prompt_message""$io_reset\n"
				prompt_items="`echo "$proposed_files" | tr [:space:] ';' `"
				prompt_select selected_file "$prompt_items" "$prompt_default" "$descriptions"
				if [ -z "$output_filename" ]
				then output_filename="$selected_file"
				fi
				if [ "$selected_file" = "none" ]
				then print_verbose "No file selected."
				else
					project_template_copy "$dir/$subdir" "$dest" "$selected_file"
				fi
				;;
			# prompt the user to select which files they want
			_if_multiselect*)
				proposed_files=`ls "$srcdir/$dir/$subdir/" | sort --ignore-case | xargs`
				selected_files=
				prompt_message=
				prompt_default=
				descriptions=
				if [ -f "$srcdir/$dir/$subdir/.cccmk" ]
				then  . "$srcdir/$dir/$subdir/.cccmk"
				else prompt_message="Select which files you wish to include in your project:"
				fi
				printf "$io_cyan""$prompt_message""$io_reset\n"
				prompt_items="`echo "$proposed_files" | tr [:space:] ';' `"
				prompt_multiselect selected_files "$prompt_items" "$prompt_default" "$descriptions"
				for i in $selected_files
				do project_template_copy "$dir/$subdir" "$dest" "$i"
				done
				;;
			# prompt the user with a y/n question, only copy over files if user answers y/yes
			_if_ask_*)
				response=
				prompt_message=
				prompt_default=
				descriptions=
				if [ -f "$srcdir/$dir/$subdir/.cccmk" ]
				then  . "$srcdir/$dir/$subdir/.cccmk"
				else prompt_message="Do you wish to include the following files ?""\n`ls -Ap "$srcdir/$dir/$subdir/" | tr ' ' '\n' `"
				fi
				printf "$io_cyan""$prompt_message""$io_reset\n"
				if [ -z "$response" ]
				then prompt_question response 'n'
				fi
				if $response
				then
					for i in `list_onlyfiles "$srcdir/$dir/$subdir"`
					do project_template_copy "$dir/$subdir" "$dest" "$i"
					done
					project_template_copy_recurse "$srcdir" "$outdir" "$dir/$subdir" "$dest"
				fi
				;;
			# only copy over files if $project_lang matches folder name part after '_if_lang_'
			_if_lang_*)
				values="` echo "$subdir" | cut -d'_' -f 4 | tr '-' ' ' `"
				if contains "$project_lang" "$values"
				then
					if [ -f "$srcdir/$dir/$subdir/.cccmk" ]
					then  . "$srcdir/$dir/$subdir/.cccmk"
					fi
					for i in `list_onlyfiles "$srcdir/$dir/$subdir"`
					do project_template_copy "$dir/$subdir" "$dest" "$i"
					done
					project_template_copy_recurse "$srcdir" "$outdir" "$dir/$subdir" "$dest"
				fi
				;;
			# only copy over files if $project_type matches folder name part after '_if_type_'
			_if_type_*)
				values="` echo "$subdir" | cut -d'_' -f 4 | tr '-' ' ' `"
				if contains "$project_type" "$values"
				then
					if [ -f "$srcdir/$dir/$subdir/.cccmk" ]
					then  . "$srcdir/$dir/$subdir/.cccmk"
					fi
					for i in `list_onlyfiles "$srcdir/$dir/$subdir"`
					do project_template_copy "$dir/$subdir" "$dest" "$i"
					done
					project_template_copy_recurse "$srcdir" "$outdir" "$dir/$subdir" "$dest"
				fi
				;;
			# any other '_if_*' folder is unknown syntax
			_if_*)
				print_error "Unknown conditional project template subfolder: '$subdir'"
				exit 1
				;;
			# these folders simply hold files which should not be added to the .cccmk project_track list
			_untracked)
				for i in `list_onlyfiles "$srcdir/$dir/$subdir"`
				do project_template_copy "$dir/$subdir" "$dest" "$i"
				done
				project_template_copy_recurse "$srcdir" "$outdir" "$dir/$subdir" "$dest"
				;;
			# for any other normal folder, recurse deeper
			*)
				project_template_copy_recurse "$srcdir" "$outdir" "$dir/$subdir" "$dest/$subdir"
				;;
		esac
	done
}



#! Recursive function used to expand/resolve special directives in files of the newly created project
project_template_text_recurse()
{
	local dir="$1"
	for i in `list_onlyfiles "$dir"`
	do
		print_verbose "reading template file: '$dir/$i'"
		cccmk_template "$dir/$i"
	done
	for subdir in `list_subfolders "$dir"`
	do
		project_template_text_recurse "$dir/$subdir"
	done
}



print_verbose "creating new project at '$command_arg_path'..."

if [ -d "$command_arg_path" ] && ! rmdir "$command_arg_path"
then
	print_error "Cannot create new project in existing folder '$command_arg_path' because it is not empty."
	print_message "Maybe you are looking to do a 'cccmk migrate' command instead ?"
	print_message "Try 'cccmk --help' for more info."
	exit 1
fi

# prompt the user for the project_lang
printf "$io_cyan""What is the programming language for this project ?""$io_reset\n"
prompt_select response "c;cpp;cs;rs;py;js;jsx;ts;tsx;" "c" '
C;
C++;
C#;
Rust;
Python;
JavaScript;
JavaScript-React;
TypeScript;
TypeScript-React;
'
project_lang="$response"
project_langsources="$project_lang"
project_langheaders=""
if [ "$project_langsources" = "c"   ] ; then project_langheaders="h"   ; fi
if [ "$project_langsources" = "c++" ] ; then project_langheaders="h++" ; fi
if [ "$project_langsources" = "cxx" ] ; then project_langheaders="hxx" ; fi
if [ "$project_langsources" = "cpp" ] ; then project_langheaders="hpp" ; fi
if [ "$project_langsources" = "adb" ] ; then project_langheaders="ads" ; fi

# prompt the user for the project_type
printf "$io_cyan""Is the project a program, or library ?""$io_reset\n"
prompt_select response "program;library;binding;" "program" '
A "program" project builds a program or application (with a "main" entry point).;
A "library" project builds a library, which can be used for other projects.;
A "binding" project builds a library, which interoperates with another language (FFI).;
'
project_type="$response"

# prompt the user for the project_author
printf "$io_cyan""Who is the author of this project ?""$io_reset\n"
prompt_text response "Type any text, which will be used as the project author name."
project_author="$response"

# prompt the user for the project_description
printf "$io_cyan""Please enter a short one-line description of this project.""$io_reset\n"
prompt_text response "Type any text, which will be used as the project description."
project_description="$response"

# automatically fill in the project year
project_year="`date "+%Y" `"

# set the default after-create operations for project
if ! [ "`type -t after_create`" = "function" ]
then
# shell command for initial project setup
after_create()
{
	if echo "$project_track" | grep -q '/_if_ask_mkfile/mkfile/all.mk'
	then make setup
	else
		if echo "$project_track" | grep -q '/.githooks/'
		then git config core.hooksPath    './.githooks'
		fi
	fi
	#./configure
}
fi

# set the default function to parse version number from versionfile for project
if ! [ "`type -t parse_versionfile`" = "function" ]
then
# shell command to parse version number from versionfile
parse_versionfile()
{
	awk '
	{
		if (/([0-9]+(\.[0-9]+)+)/)
		{
			if (match($$0, /([0-9]+(\.[0-9]+)+)/))
			{
				print substr($$0, RSTART + 1, RLENGTH - 1);
			}
		}
	}
	' "$1"
}
fi

(
	# create project folder and cd inside it
	mkdir "$command_arg_path"
	cd    "$command_arg_path"

	# create '.cccmk' project tracker file
	echo '#!/bin/sh -e' > "./$project_cccmkfile"
	chmod 755 "./$project_cccmkfile"
	{	echo ""
		echo "project_name='$command_arg_name'"
		echo "project_year='$project_year'"
		echo "project_link='$project_link'"
		echo "project_docs='$project_docs'"
		echo "project_repo='$project_repo'"
		echo "project_author='$project_author'"
		echo "project_description='$project_description'"
		echo "project_lang='$project_lang'"
		echo "project_langversion='$project_langversion'"
		echo "project_langsources='$project_langsources'"
		echo "project_langheaders='$project_langheaders'"
		echo "project_type='$project_type'"
		echo "project_cccmk='$project_cccmk'"
		echo "project_versionfile='$project_versionfile'"
		echo "project_packagefile='$project_packagefile'"
		echo "project_track_paths='$project_track_paths'"
	} >> "$project_cccmkfile"
	# parse the newly created .cccmk prpject tracker file
	. "./$project_cccmkfile"

	# add tracked files to the '.cccmk' file (with their respective cccmk template git revisions)
	echo "project_track='" >> "$project_cccmkfile"
	project_template_copy_recurse "$CCCMK_PATH_PROJECT" "." "."
	echo "'" >> "$project_cccmkfile"
	# parse the newly created .cccmk prpject tracker file
	. "./$project_cccmkfile"
	# replace %[vars]% in newly copied-over files
	project_template_text_recurse "."

	# create initial project version file
	echo "$command_arg_name@0.0.0-?" > "$project_versionfile"
	# set up git repo for new project
	git init
	git add --all
	git branch -m master
	git commit -m "initial commit"
	# initial setup for project, after creation
	after_create
	

	if $verbose
	then
		print_verbose "Here is the folder tree of the newly created project:"
		if tree --version > /dev/null
		then tree -a -I '.git' .
		else print_warning "This computer has no 'tree' command installed, cannot display project folder tree."
		fi
		print_verbose "Here are the contents of the '$project_cccmkfile' file:"
		cat "$project_cccmkfile"
	fi
)
print_success "Created new project '$command_arg_name' at '$command_arg_path'"
