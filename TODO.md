# TODO list for cccmk

- Refactor all `.mk` scripts to clean up foldername variables, so they never contain any `/` slash characters
- Implement peer-dependency recursive-tree logic (create a standard format for a `/mkfile/lists/packages.lock` file)
- Implement usage of `git tag` command for auto-version logic
- Implement nested-block capability for the `template.awk` script
- Refactor `make init` -> `make setup`
- Implement conan.io package manager interop
- Add package `.mk` script for WxWidgets
- Add package `.mk` script for ImGui
- Create "hello world" example projects for each major language in an `/examples` folder
