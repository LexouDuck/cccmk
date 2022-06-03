#!/usr/bin/sh -e

# This script is a work-in-progress, and is not guaranteed to work in a cross-platform manner

# destination folder in which cccmk should be installed
INSTALL_DIR=~/.cccmk
# destination folder in which to put the `cccmk` symbolic-link command
COMMAND_DIR=/usr/local/bin

echo "If you want a custom cccmk installation, type in the URL of the git repo fork you wish to use."
echo "Otherwise, if you just wish to use the default project template, simply press RETURN/ENTER."
read -p "> " GIT_URL
if [ -z "$GIT_URL" ]
then git clone https://github.com/LexouDuck/cccmk.git "$INSTALL_DIR"
else git clone "$GIT_URL" "$INSTALL_DIR"
fi

if ! [ -d "$INSTALL_DIR" ]
then
	echo "ERROR: the installation directory was not created properly: $INSTALL_DIR"
	exit 1
fi
if ! [ -d "$COMMAND_DIR" ]
then
	echo "ERROR: the directory for the cccmk command does not exist: $COMMAND_DIR"
	exit 1
fi
ln -s "$INSTALL_DIR/scripts/cccmk.sh" "$COMMAND_DIR/cccmk" || sudo \
ln -s "$INSTALL_DIR/scripts/cccmk.sh" "$COMMAND_DIR/cccmk" || exit 1
chmod 755 "$COMMAND_DIR/cccmk" || sudo \
chmod 755 "$COMMAND_DIR/cccmk" || exit 1
echo "cccmk was successfully installed, at $COMMAND_DIR"
