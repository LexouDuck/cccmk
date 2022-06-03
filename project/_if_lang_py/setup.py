#!/usr/bin/env python3
"""
A setuptools based setup module.

To learn more about distributing python packages, see:
https://packaging.python.org/en/latest/distributing.html
https://github.com/pypa/sampleproject
https://realpython.com/python-wheels/  # more info on packaging dynamic libraries here
https://stackoverflow.com/questions/31380578/how-to-avoid-building-c-library-with-my-python-package
https://packaging.python.org/en/latest/overview/
https://blog.ian.stapletoncordas.co/2019/02/distributing-python-libraries-with-type-annotations.html
"""
from os import path, listdir
from sys import platform
# To use a consistent encoding
from codecs import open

# Always prefer setuptools over distutils
from setuptools import setup, find_packages



# Get a string representing the target OS/platform
def get_os_name():
    if platform == 'darwin':
        return 'macos'
    elif platform == 'linux':
        return 'linux'
    elif platform == 'win32' or platform == 'cygwin':
        return 'win64'
    else:
        raise RuntimeError("get_os_name(): unsupported platform")



# Get the absolute path of the project folder
here = path.abspath(path.dirname(__file__))



%%if tracked(_if_ask_mkfile/Makefile)
# The list of dynamic libraries which should be copied over as part of this package
project_dynlibs = []
try:
    binfolder = path.join(here,"..","C_client","bin",get_os_name(),"dynamic")
    project_dynlibs = listdir(binfolder)
except Exception as ex:
    print(f"Error when checking for dynamic libraries in folder: {binfolder}\n{repr(ex)}")
%%end if

%%if tracked(_if_ask_mkfile/mkfile/rules/version.mk)
# The project/package name (from the %[versionfile]% file)
project_name = "?"
# The project/package version (from the %[versionfile]% file)
project_version = "?"
try:
    file_version = '%[versionfile]%'
    with open(path.join(here, file_version), encoding='utf-8') as f:
        file = f.read()
        separator = file.index('@')
        project_name = file[0:separator]
        project_version = file[separator+1:file.index('-', separator+1)]
except Exception as ex:
    print(f"Error when reading project version file: {file_version}\n{repr(ex)}")
%%end if

# Get the project description from the README file
project_readme = ""
try:
    file_readme = 'README.md'
    with open(path.join(here, file_readme), encoding='utf-8') as f:
        project_readme = f.read()
except Exception as ex:
    print(f"Error when reading project readme file: {file_version}\n{repr(ex)}")



setup(
    name             = "%[name]%",
    version          = "%[version]%",
    description      = "%[description]%",
    long_description = project_readme,
    author           = "%[author]%",
    author_email     = "%[email]%",
    classifiers      = [
        "Programming Language :: Python :: %[langversion]%",
        "Intended Audience :: Developers",
        "Topic :: ?",
        "License :: ?",
        "Development Status :: ?",
    ],
    python_requires      = '>=%[langversion]%',
    install_requires     = [],
    include_package_data = True,
    package_dir          = {
        "": "src",
    },
    packages             = [
    ],
    package_data         = {
    },
)
