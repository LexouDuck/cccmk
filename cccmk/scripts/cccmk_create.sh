#!/bin/sh -e



print_verbose "creating new project at '$command_arg_path'..."

# prompt the user for the project type
echo "Is the project a program, or library ? [program/library/cancel]"
read -p "> " response
response=`echo "$response" | tr [:upper:] [:lower:]` # force lowercase
project_type=
case $response in
	program|library)
		project_type=$response
		;;
	cancel)
		print_message "Operation cancelled."
		exit 1
		;;
	*)	print_error "Invalid answer, should be either 'program' or 'library'."
		exit 1
		;;
esac
echo ''



#! Recursive function used to copy over template files from the `cccmk/project` folder
copy_from_template()
{
	local srcdir="$1"
	local outdir="$2"
	local dir="$3"
	local rev="`(cd "$cccmk_install" && git rev-parse HEAD )`"
	# create destination folder
	mkdir -p "$outdir/$dir"
	# copy over all regular files
	for i in `list_onlyfiles "$srcdir/$dir"`
	do
		cp -p         "$srcdir/$dir/$i"   "$outdir/$dir/$i"
		echo "$rev"":""$srcdir/$dir/$i"":""$outdir/$dir/$i" >> "$project_cccmkfile"
	done
	# iterate over all subfolders, and check '_if_*' folders to conditionally copy certain files
	for subdir in `list_subfolders "$srcdir/$dir"`
	do
		case "$subdir" in
			# prompt the user to select one out of several files
			_if_select)
				if [ -f "$srcdir/$dir/$subdir/.cccmk" ]
				then  . "$srcdir/$dir/$subdir/.cccmk"
				else prompt_message="Select the file you wish to include in your project:"
				fi
				echo "$prompt_message"
				prompt_select selected_file
				cp -p         "$srcdir/$dir/$subdir/$selected_file"   "$outdir/$dir/$selected_file"
				echo "$rev"":""$srcdir/$dir/$subdir/$selected_file"":""$outdir/$dir/$selected_file" >> "$project_cccmkfile"
				;;
			# prompt the user to select which files they want
			_if_multiselect)
				if [ -f "$srcdir/$dir/$subdir/.cccmk" ]
				then  . "$srcdir/$dir/$subdir/.cccmk"
				else prompt_message="Select which files you wish to include in your project:"
				fi
				proposed_files=`ls "$srcdir/$dir/$subdir/" | sort --ignore-case | xargs`
				selected_files=
				echo "$prompt_message"
				prompt_multiselect selected_files `echo "$proposed_files" | tr [:space:] ';' `
				for i in ${selected_files[@]}
				do
					cp -p         "$srcdir/$dir/$subdir/$i"   "$outdir/$dir/$i"
					echo "$rev"":""$srcdir/$dir/$subdir/$i"":""$outdir/$dir/$i" >> "$project_cccmkfile"
				done
				;;
			# only copy over files if player answers y/yes to the '_if_flag_*/.cccmk' question
			_if_flag_*)
				if [ -f "$srcdir/$dir/$subdir/.cccmk" ]
				then  . "$srcdir/$dir/$subdir/.cccmk"
				else prompt_message="Do you wish to include the following files ?""\n`ls "$srcdir/$dir/$subdir/"`"
				fi
				prompt_question response "$prompt_message"
				if $response
				then
					for i in "$srcdir/$dir/$subdir/"*
					do
						cp -p         "$srcdir/$dir/$subdir/$i"   "$outdir/$dir/$i"
						echo "$rev"":""$srcdir/$dir/$subdir/$i"":""$outdir/$dir/$i" >> "$project_cccmkfile"
					done
				fi
				;;
			# only copy over files if $project_type matches folder name part after '_if_type_'
			_if_type_*)
				if [ "$subdir" == "_if_type_$project_type" ]
				then
					for i in "$srcdir/$dir/$subdir/"*
					do
						cp -p         "$srcdir/$dir/$subdir/$i"   "$outdir/$dir/$i"
						echo "$rev"":""$srcdir/$dir/$subdir/$i"":""$outdir/$dir/$i" >> "$project_cccmkfile"
					done
				fi
				;;
			_if_*)
				print_error "Unknown conditional project template subfolder: '$subdir'"
				exit 1
				;;
			# for any other normal folder, recurse deeper
			*)
				copy_from_template "$srcdir" "$outdir" "$dir/$subdir"
				;;
		esac
	done
}



# TODO LICENSE file logic ?
# TODO replace [[x]] logic ?
(
	# create project folder and cd inside it
	mkdir "$command_arg_path"
	cd    "$command_arg_path"
	# create '.cccmk' project tracker file
	echo '#!/bin/sh -e' > "./$project_cccmkfile"
	chmod 755 "./$project_cccmkfile"
	{	echo ""
		echo "project_type='$project_type'"
		echo "project_cccmk='$project_cccmk'"
		echo "project_mkfile='$project_mkfile'"
		echo "project_mkpath='$project_mkpath'"
		echo "project_versionfile='$project_versionfile'"
		echo "project_packagefile='$project_packagefile'"
		echo "project_track='"                 
	} >> "$project_cccmkfile"
	# replace [[vars]] in templates
	project_replace_name="$command_arg_name"
	project_replace_path="$command_arg_path"
	project_replace_year="`date "+%Y"`"
	project_replace_author="???" # TODO prompt_text() function call ?
	# add mkfile scripts to the '.cccmk' file (with their respective cccmk template git revisions)
	copy_from_template "$CCCMK_PATH_PROJECT" "." "."
	echo "'" >> "$project_cccmkfile"
	# create initial project version file
	echo "$command_arg_name@0.0.0-?" > "$project_versionfile"
	# set up git repo for new project
	git init
	git branch -m master
	git add --all
	git commit -m "initial commit"
	# set up other git/version management things
	make init
	make version

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
