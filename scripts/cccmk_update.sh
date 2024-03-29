#!/bin/sh -e



if ! [ -f "./$project_cccmkfile" ]
then
	print_error "The current folder is not a valid cccmk project folder (needed for command 'cccmk update')"
	exit 1
else . "./$project_cccmkfile"
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
tracked_files_ccc=""
tracked_files_pwd=""

for i in $project_track
do
#	trackedfile_ccc_rev="`echo "$i" | cut -d':' -f 1 `"
	trackedfile_cccpath="`echo "$i" | cut -d':' -f 2 `"
	trackedfile_pwdpath="`echo "$i" | cut -d':' -f 3 `"
	tracked_files_ccc="$tracked_files_ccc $trackedfile_cccpath"
	tracked_files_pwd="$tracked_files_pwd $trackedfile_pwdpath"
done

if [ -z "$command_arg_path" ]
then
	print_verbose "No scripts filepath(s) given, so all tracked mkfile scripts will be updated."
	request_files="$tracked_files_pwd"
else
	command_arg_path="`echo "$command_arg_path" | sed 's|\./||g'`"
	# iterate over all user-specified files, to populate 'request_files'
	for i in $command_arg_path
	do
		if ! [ -z "` echo $tracked_files_pwd | grep -w "$i" `" ]
		then
			if [ -d "$i" ] # if this is a folder, recursively add any tracked files inside
			then
				for f in $tracked_files_pwd
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
				print_warning "Tracked file does not exist: '$i'"
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

	#! The file in the current project
	file_pwd="$trackedfile_pwdpath"
	#! The equivalent filepath tracked from the cccmk templates
	file_ccc="$trackedfile_cccpath"

	#! The URL of the tracked template file
	file_url="$cccmk_git_url/$trackedfile_ccc_rev/$cccmk_dir_project/$file_ccc"

	mkdir -p "`dirname "$path_tmp/$file_pwd" `"
	errormsg=""
	fetched=false
	# get tracked template from the internet
	while ! $fetched
	do
		printf "cccmk: ""$io_blue""message""$io_reset"": Updating file: '$file_pwd' -> "  >&2
		#print_verbose "fetching template file from url: '$file_url'"
		curl --silent "$file_url" > "$path_tmp/$file_pwd.old"
		if ! [ -f "$path_tmp/$file_pwd.old" ]
		then
			errormsg="Could not retrieve tracked template from repo at '$file_url'."
			continue
		elif [ -z "`cat "$path_tmp/$file_pwd.old" `" ]
		then
			errormsg="Retrieved empty template file from repo at '$file_url'."
			rm -f "$path_tmp/$file_pwd.old"
			continue
		elif ! [ -z "` head -1 "$path_tmp/$file_pwd.old" | grep 'Moved Permanently' `" ]
		then
			errormsg="Redirection error for template from repo at '$file_url'."
			rm -f "$path_tmp/$file_pwd.old"
			continue
		elif ! [ -z "` head -1 "$path_tmp/$file_pwd.old" | grep '^[45][0-9][0-9]: ' `" ]
		then
			errormsg="`cat "$path_tmp/$file_pwd.old" `"
			rm -f "$path_tmp/$file_pwd.old"
			response=""
			printf "$io_red""ERROR""$io_reset\n"
			print_failure "Error while retrieving template from repo at '$file_url':"
			print_failure "$errormsg"
			printf "$io_cyan""Could not get latest project template for file:$io_reset $file_ccc\n"
			printf "$io_cyan""It is possible that the template file has been moved to another path.""$io_reset\n"
			printf "$io_cyan""Please specify the new path of this project template file, if applicable.""$io_reset\n"
			prompt_text response "Type the new template file's path, or an empty string to abort the update for this file." "$file_ccc"
			if [ -z "$response" ]
			then
				print_message "Update operation aborted for file: $file_pwd"
				break
			else
				print_message "Assuming file path has changed: '$file_ccc' -> '$response'"
				file_ccc="$response"
				file_url="$cccmk_git_url/$trackedfile_ccc_rev/$cccmk_dir_project/$file_ccc"
				continue
			fi
		else
			cccmk_template "$path_tmp/$file_pwd.old"
			fetched=true
		fi
	done
	# skip over to the next file, if there was a problem when fetching
	if ! $fetched
	then
		printf "$io_red""ERROR""$io_reset\n"
		print_failure "$errormsg"
		continue
	fi

	# check that the "new template" source file actually exists
	if ! [ -f "$path_ccc/$file_ccc" ]
	then
		printf "$io_red""ERROR""$io_reset\n"
		print_failure "Could not find source template file: $path_ccc/$file_ccc"
		continue # exit 1
	else
		cccmk_template "$path_ccc/$file_ccc" "$path_tmp/$file_pwd.new"
	fi

	# fix file permissions for the newly downloaded "old template" file
	chmod "`file_getmode "$path_ccc/$file_ccc" `" "$path_tmp/$file_pwd.old"

	response=false
	identical=false
	overwrite=false
	conflicts=
	# check if files exist, and prompt user accordingly
	if [ -f "$path_pwd/$file_pwd" ]
	then
		if cmp -s "$path_tmp/$file_pwd.new" "$path_pwd/$file_pwd"
		then
			printf "$io_green""IDENTICAL""$io_reset\n"
			response=true
			identical=true
		else
			printf "$io_yellow""DIFFERENT""$io_reset\n"
			if cmp -s "$path_tmp/$file_pwd.old" "$path_pwd/$file_pwd"
			then printf " - user-side changes: no\n"
			else printf " - user-side changes: yes `cccmk_diff_brief "$path_tmp/$file_pwd.old" "$path_pwd/$file_pwd" | cut -d' ' -f 3 `\n"
			fi
			if cmp -s "$path_tmp/$file_pwd.old" "$path_tmp/$file_pwd.new"
			then printf " - cccmk-side updates: no\n"
			else printf " - cccmk-side updates: yes `cccmk_diff_brief "$path_tmp/$file_pwd.old" "$path_tmp/$file_pwd.new" | cut -d' ' -f 3 `\n"
			fi
			printf "$io_cyan""How do you wish to update '$file_pwd' ?""$io_reset\n"
			identical=true
			while $identical
			do
				prompt_select response 'merge;overwrite;unchanged;show_diff' 'merge' '
					Do a 3-way diff/merge (using the git diff3 algorithm), keeping all changes from both files;
					Overwrite your local project file with the latest template from cccmk, losing your changes;
					Leave your local project file unchanged as-is, and proceed;
					Show differences between the files, and ask again after reviewing diff;
				'
				case $response in
					(merge)     response=true  ; overwrite=false ;;
					(overwrite) response=true  ; overwrite=true  ;;
					(unchanged) response=false ; overwrite=false ;;
					(show_diff)
						#print_message "NOTE: the cccmk template is shown as old/red, and your file is shown as new/green."
						cccmk_diff_fancy "$path_tmp/$file_pwd.old" "$path_pwd/$file_pwd"
						cccmk_diff_fancy "$path_tmp/$file_pwd.old" "$path_tmp/$file_pwd.new"
						continue ;;
					(*) print_message "Aborting operation" ; exit 1 ;;
				esac
				identical=false
			done
		fi
	else
		printf "$io_yellow""MISSING""$io_reset\n"
		print_warning "Could not find project tracked file '$path_pwd/$file_pwd'."
		printf "$io_cyan""Do you wish to create the file '$file_pwd' using the template ?""$io_reset\n"
		prompt_question response 'n'
		identical=false
	fi

	# actually update the file in question
	if $response
	then
		if $identical
		then print_verbose "The file is identical to the cccmk template: '$file_ccc'"
		else print_verbose "Updating file: '$file_pwd'..."
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
					>  "$path_tmp/.tmp" \
					|| { print_warning "CONFLICT: merge conflicts in file: '$file_pwd'" ; conflicts="$conflicts $file_pwd"; }
					chmod "`file_getmode "$path_pwd/$file_pwd" `" "$path_tmp/.tmp"
					mv "$path_tmp/.tmp" "$path_pwd/$file_pwd"
				fi
			elif [ -f "$path_tmp/$file_pwd.old" ]; then cp -p "$path_tmp/$file_pwd.old" "$path_pwd/$file_pwd"
			elif [ -f "$path_tmp/$file_pwd.new" ]; then cp -p "$path_tmp/$file_pwd.new" "$path_pwd/$file_pwd"
			else
				print_failure "Could not update file '$file_pwd'"
				continue
			fi
			print_success "Updated file '$file_pwd'."
		fi
		# apply new tracking revision hash to .cccmk project tracker file
		awk_inplace "$path_pwd/$project_cccmkfile" \
			-v file_ccc="$file_ccc" \
			-v file_pwd="$file_pwd" \
			-v rev="$cccmk_git_rev" \
			-f "$CCCMK_PATH_SCRIPTS/utils.awk" \
			-f "$CCCMK_PATH_SCRIPTS/cccmk_track.awk"
		# keep track all previously updated/merged files
		updated_files="$updated_files $trackedfile_pwdpath"
	else
		print_message "Update operation cancelled for file: $file_pwd"
		continue
	fi
done
print_success "Finished updating all tracked files."
if ! [ -z "$conflicts" ]
then
	print_warning "Since there were some merge conflicts, make sure you check these files:"
	for i in $conflicts
	do print_warning "CONFLICT: $i"
	done
fi
# cleanup temp files
rm -rf "$path_tmp"
