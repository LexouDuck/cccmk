#!/bin/sh -e



if ! [ -z "$project_missing" ]
then
	print_error "The current folder is not a valid cccmk project folder (needed for command 'cccmk update')"
	exit 1
else . "$project_cccmkfile"
fi

#! current project folder
path_pwd="."
#! local cccmk install folder which stores the project template
path_ccc="$CCCMK_PATH_PROJECT"

#! list of files to be updated/merged
request_files=""
#! list of updated/merged files
updated_files=""
#! list of all tracked files in the current project
tracked_files=""

for i in $project_track
do
#	trackedfile_ccc_rev="`echo "$i" | cut -d':' -f 1 `"
#	trackedfile_cccpath="`echo "$i" | cut -d':' -f 2 `"
	trackedfile_pwdpath="`echo "$i" | cut -d':' -f 3 `"
	tracked_files="$tracked_files $trackedfile_pwdpath"
done

if [ -z "$command_arg_path" ]
then
	print_verbose "No scripts filepath(s) given, so all tracked mkfile scripts will be updated."
	request_files="$tracked_files"
else
	command_arg_path="`echo "$command_arg_path" | sed 's|\./||g'`"
	# iterate over all user-specified files, to populate 'request_files'
	for i in $command_arg_path
	do
		if ! [ -z "` echo $tracked_files | grep "$i" `" ]
		then
			if [ -d "$i" ] # if this is a folder, recursively add any tracked files inside
			then
				for f in $tracked_files
				do
					if ! [ -z "` echo $f | grep "^$i/" `" ]
					then request_files="$request_files $f"
					fi
				done
			elif [ -f "$i" ] # if this is a regular file, add it
			then
				request_files="$request_files $i"
			else # the file/folder doesnt exist
				request_files="$request_files $i"
			fi
		else print_warning "File is not tracked by '$project_cccmkfile' file: '$i'"
		fi
	done
fi


#! the temporary folder to hold templates fetched from the web
path_tmp=".cccmk_update"
rm -rf "$path_tmp"
mkdir "$path_tmp"

# iterate over all cccmk-tracked files
for i in $project_track
do
	trackedfile_ccc_rev="`echo "$i" | cut -d':' -f 1 `"
	trackedfile_cccpath="`echo "$i" | cut -d':' -f 2 `"
	trackedfile_pwdpath="`echo "$i" | cut -d':' -f 3 `"
	if ! [ -z "$command_arg_path" ]
	then
		if [ -z "` echo $request_files | grep -w "$trackedfile_pwdpath" `" ]
		then continue # user did not ask for this file
		fi
	fi

	#! The URL of the tracked template file
	file_url="$cccmk_git_url/$trackedfile_ccc_rev/cccmk/$cccmk_dir_project/$trackedfile_cccpath"

	#! The file in the current project
	file_pwd="$trackedfile_pwdpath"
	#! The equivalent filepath tracked from the cccmk templates
	file_ccc="$trackedfile_cccpath"

	mkdir -p "`dirname "$path_tmp/$file_pwd" `"
	# get tracked template from the internet
	print_verbose "fetching template file from url: '$file_url'"
	curl --silent "$file_url" > "$path_tmp/$file_pwd.old"
	if ! [ -f "$path_tmp/$file_pwd.old" ]
	then
		print_error "Could not retrieve tracked template from repo at '$file_url'."
		rm -f "$path_tmp/$file_pwd.old" ; continue
	elif [ -z "`cat "$path_tmp/$file_pwd.old" `" ]
	then
		print_error "Retrieved empty template file from repo at '$file_url':"
		rm -f "$path_tmp/$file_pwd.old" ; continue
	elif ! [ -z "` head -1 "$path_tmp/$file_pwd.old" | grep 'Moved Permanently' `" ]
	then
		print_error "Redirection error for template from repo at '$file_url':"
		rm -f "$path_tmp/$file_pwd.old" ; continue
	elif ! [ -z "` head -1 "$path_tmp/$file_pwd.old" | grep '^[45][0-9][0-9]: ' `" ]
	then
		print_error "Error while retrieving template from repo at '$file_url':"
		print_error "` cat "$path_tmp/$file_pwd.old" `"
		rm -f "$path_tmp/$file_pwd.old" ; continue
	else
		cccmk_template "$path_tmp/$file_pwd.old"
	fi

	# check that the source template file exists
	if ! [ -f "$path_ccc/$file_ccc" ]
	then print_error "Could not find source template file '$path_ccc/$file_ccc'."
		continue # exit 1
	else
		cccmk_template "$path_ccc/$file_ccc" "$path_tmp/$file_pwd.new"
	fi

	response=false
	identical=false
	overwrite=false
	# check if files exist, and prompt user accordingly
	if [ -f "$path_pwd/$file_pwd" ]
	then
		if cmp -s "$path_tmp/$file_pwd.new" "$path_pwd/$file_pwd"
		then
			response=true
			identical=true
		else
			print_message "The file '$file_pwd' differs from the cccmk template" # (see diff above)"
			#print_message "NOTE: the cccmk template is shown as old/red, and your file is shown as new/green."
			if cmp -s "$path_tmp/$file_pwd.old" "$path_pwd/$file_pwd"
			then echo " - user-side changes: no"
			else echo " - user-side changes: yes"
				if $verbose
				then cccmk_diff "$path_tmp/$file_pwd.old" "$path_pwd/$file_pwd"
				fi
			fi
			if cmp -s "$path_tmp/$file_pwd.old" "$path_tmp/$file_pwd.new"
			then echo " - cccmk-side updates: no"
			else echo " - cccmk-side updates: yes"
				if $verbose
				then cccmk_diff "$path_tmp/$file_pwd.old" "$path_tmp/$file_pwd.new"
				fi
			fi
			echo "How do you wish to update '$file_pwd' ?"
			prompt_select response 'merge;overwrite;unchanged;'
			case $response in
				(merge)     response=true  ; overwrite=false ;;
				(overwrite) response=true  ; overwrite=true  ;;
				(unchanged) response=false ; overwrite=false ;;
				(*) print_message "Aborting operation" ; exit 1 ;;
			esac
			identical=false
		fi
	else
		print_warning "Could not find project tracked file '$path_pwd/$file_pwd'."
		echo "Do you wish to create the file '$file_pwd' using the template ?"
		prompt_question response 'n'
		identical=false
	fi

	# actually update the file in question
	if $response
	then
		if $identical
		then print_message "The file is identical to the cccmk template: '$file_pwd'"
		else print_message "Updating file: '$file_pwd'..."
			# do a git 3-way merge to update the file in question
			print_verbose "performing 3-way diff/merge:\n%s\n%s\n%s\n%s" \
				" - project_track modified file: [`file_timestamp "$path_pwd/$file_pwd"`] $path_pwd/$file_pwd" \
				" - last tracked cccmk template: [`file_timestamp "$path_tmp/$file_pwd"`] $path_tmp/$file_pwd" \
				" - localinstall cccmk template: [`file_timestamp "$path_ccc/$file_ccc"`] $path_ccc/$file_ccc" \
				""
			if [ -f "$path_pwd/$file_pwd" ]
			then
				if $overwrite
				then cp -p "$path_tmp/$file_pwd.new" "$path_pwd/$file_pwd"
				else
					git merge-file -p --diff3 \
						"$path_pwd/$file_pwd" \
						"$path_tmp/$file_pwd.old" \
						"$path_tmp/$file_pwd.new" \
					>  "$path_tmp/.tmp" || print_warning "CONFLICT: merge conflicts in file: '$file_pwd'"
					mv "$path_tmp/.tmp" "$path_pwd/$file_pwd"
				fi
			elif [ -f "$path_tmp/$file_pwd.old" ]; then cp -p "$path_tmp/$file_pwd.old" "$path_pwd/$file_pwd"
			elif [ -f "$path_tmp/$file_pwd.new" ]; then cp -p "$path_tmp/$file_pwd.new" "$path_pwd/$file_pwd"
			else print_failure "Could not update file '$file_pwd'" ; continue
			fi
			print_success "Updated file '$file_pwd'."
		fi

		# apply new tracking revision hash to .cccmk project tracker file
		awk_inplace "$path_pwd/$project_cccmkfile" \
			-v filepath="$file_pwd" \
			-v rev="$cccmk_git_rev" \
		'{
			if (/^[0-9a-fA-F]{40}:/)
			{
				split($0, parts, /:/);
				if (parts[3] == filepath)
				{
					print rev ":" parts[2] ":" filepath;
				}
				else print;
			}
			else print;
		}'
		# keep track all previously updated/merged files
		updated_files="$updated_files $trackedfile_pwdpath"
	else
		print_message "Update operation cancelled for '$file_pwd'."
		continue
	fi
done
print_verbose "finished updating files."
# cleanup temp files
rm -rf "$path_tmp"
