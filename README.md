# cccmk

`cccmk` is a tool to facilitate harmonizing files and folders across all of your projects, so as to ensure that they follow the "project template" that suits you.

`cccmk` is language-agnostic: it only deals with text files and folders, so anything goes! You can create any "project template" which suits your needs - see the "Documentation" section below to learn more.
`cccmk` comes with a fully-featured "project template" for several popular programming languages, which follow conventional folder structure.

`cccmk` is implemented entirely in `.sh` shell scripts, so it is fully modifiable by the end-user (it follows the MIT license, so you are free to do whatever you wish with it).

NOTE: `cccmk` is not SCM-agnostic! Currently, it assumes that your SCM tool is `git` - but this will be made more generic, in the future.



### Rationale

You may think that `cccmk` is redundant, because on the surface it seems that this is similar to a typical SCM tool (such as `git`, `svn`, etc), but the primary goal of `cccmk` is to be used _alongside_ your SCM tool of choice, to harmonize files across your different repositories.
With this goal in mind, `cccmk` is much simpler in how it tracks files than, say for instance, `git`: whereas with `git` everything is tracked by default, and you purposefully create a `./.gitignore` file to exclude certain files from the repo ; with `cccmk`, the `./.cccmk` file only lists those files which are part of your "project template", so they can be tracked, compared, and updated.


The name `cccmk` is derived from the ++C language, which is often called CCC, after its common file extension `*.ccc`, and its standard library, [libccc](https://github.com/LexouDuck/libccc).
It is worth noting that `cccmk` was originally designed as a build system management tool for projects which use `make`, and the aim was to use `cccmk` to help maintain a complex multi-makefile build system, which offers many `make` commands akin to package manager tools of several modern programming languages (like `cargo` for Rust, or `npm/npx` for JavaScript/TypeScript). This makefile-based build system is provided in the default "project template", in the `cccmk/project/_if_ask_mkfile/` folder.



### Installation

While it is simple enough to download this repo as a .zip and manually install cccmk, it is recommended that you clone the repo proper, using `git clone` (see "Step 1, method A: read-only installation").
If you wish to customize the "project template", or `cccmk` itself, then it is probably best that you fork this repository, so that you can then `git push` your custom changes to your own forked repo (see "Step 1, method B: customizable installation").

- **Step 1, method A: read-only installation**

So, start by cloning the `cccmk` repo directly:
```sh
git clone  https://github.com/LexouDuck/cccmk.git  ~/.cccmk
```

- **Step 1, method B: customizable installation**

So, start by forking the repo (learn more here: https://docs.github.com/en/get-started/quickstart/fork-a-repo).
When you clone your forked repo, you may want to use an SSH address rather than HTTPS, depending on your use-case:
```sh
git clone  git@github.com:<USERNAME>/cccmk.git  ~/.cccmk
```

- **Step 2: installing the `cccmk` command**

The above step will create your `cccmk` installation, in the standard `~/.cccmk/` directory.

Then, we simply need to let your shell know where to find the `cccmk` command:
```sh
sudo ln -s  ~/.cccmk/scripts/cccmk.sh  /usr/local/bin/cccmk
sudo chmod 755 /usr/local/bin/cccmk # On most systems, this isn't necessary
```
That should be it ! Try running `cccmk help` to see if it works.

NOTE: If you use a windows machine, then, depending on the shell that you use, there is perhaps no `chmod` command, there is probably no `sudo` command, and there is most likely no simple working `ln -s` command to create symlinks.
In this case, the best manner to have a working `cccmk` command is to add your installation folder to your PATH env variable, like so:
```sh
export PATH="$PATH:~/.cccmk/scripts/"
mv ~/.cccmk/scripts/cccmk.sh ~/.cccmk/scripts/cccmk # remove the .sh file extension from the main entry-point script
```



### Usage

`cccmk` has three main features/commands:
- `cccmk create`: creating new projects, using the "project template"
- `cccmk diff`: comparing tracked project files to the corresponding "project template" source file
- `cccmk update`: updating files in existing projects, to synchronize them with their "project template" source

To learn more, try using `cccmk help`.



### Documentation

Each project template file is processed by the `template.awk` templater program (located at `cccmk/scripts/template.awk`), here is an explanation of how this templater program works:
```c
// This script creates a text file from a project template text file
// Here is an example of how this script should be called:
	$ awk \
		-v variables=" foo=FOO; bar=BAR; " \
		-v functions=" myfunc1(2) myfunc2(0) " \
		-f ~/.cccmk/scripts/util.awk \
		-f ~/.cccmk/scripts/template-functions.awk \
		-f ~/.cccmk/scripts/template.awk \
		"$inputfile"

// As for the syntax of the template file's contents, essentially 3 directives are accepted:

// 1. variable (string expansion): is replaced with the content of the variable named 'varname'
	%[varname]%

// 2. loop (array expansion): is replaced with 'n' lines, for each element of the 'array' variable
	%%for (varname): // (single-line version) some code here
	%%for (varname)
	// (multi-line version - note the absence of ':') some code here
	%%end for

// 3. conditional: is put into the output only if the condition evaluates to true
	%%if myfunc(foo,bar): // (single-line version) some code here
	%%if myfunc(foo,bar)
	// (multi-line version - note the absence of ':') some code here
	%%end if
```
The functions which can be used in conditional directives are implemented in `cccmk/scripts/template-functions.awk`.
By default, a couple of useful functions are provided:
- `%%if true()`: Always include the given section
- `%%if false()`: Never include the given section
- `%%if is(varname, text)`: Checks if the variable `varname` contains a value which is identical to the given `text`.
- `%%if matches(varname, regexp)`: Checks if the variable `varname` matches the given `regexp` regular expression.
- `%%if tracked(filepath)`: Checks if the given project template `filepath` is tracked in the project's `.cccmk` file.



### Repo folder structure

- `./project`: holds the template source files used when creating a new project with `cccmk new`.
- `./scripts`: holds the source code sheel scripts which make up the `cccmk` toolchain.
