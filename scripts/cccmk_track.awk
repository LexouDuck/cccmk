#!/bin/awk

#! This script updates one line of a `.cccmk` project tracker file
#! It receives three variables:
#!	- `file_ccc`:	The path of the project template source file
#!	- `file_pwd`:	The path of file in the local project
#!	- `rev`:		The (updated) commit revision hash to write

{
	if (/^[0-9_a-zA-Z]+:/)
	{
		split($0, parts, /:/);
		if (parts[3] == file_pwd)
		{
			if (/^[0-9a-fA-F]{40}:/) {}
			else
			{
				print_warning(".cccmk project tracker file was not a tracking a commit hash:\n" $0);
			}
			$0 = rev ":" file_ccc ":" file_pwd;
		}
	}
	print;
}
