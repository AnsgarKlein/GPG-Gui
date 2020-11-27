#!/usr/bin/env python3

"""
This script prints all vala source files for this project
as relative paths starting at source directory.
"""

import os, sys, re

# Relative path from this script to project directory
PRJ_PATH = [ '..' ]

# Relative path from this script to source directory
SRC_PATH = [ '..', 'src' ]

def main():
    # cd to src directory
    os.chdir(os.path.dirname(sys.argv[0]))
    for d in SRC_PATH:
        os.chdir(d)

    # Get all vala files
    files = vala_files(os.path.abspath(os.getcwd()))

    # Convert to relative paths
    files = [ os.path.relpath(f, os.path.join(*SRC_PATH)) for f in files ]

    # Sort
    files.sort()

    # Print
    for f in files:
        print(f)

def vala_files(path):
    """Return all files recursively starting at given path"""

    children = [ os.path.join(path, child) for child in os.listdir(path) ]
    subfiles = ( child for child in children if os.path.isfile(child) )
    subdirs  = ( child for child in children if os.path.isdir(child) )

    # Create list of vala files
    lst = []

    # Add every file that ends with .vala to list
    reg = re.compile('\.vala$', re.IGNORECASE)
    for f in subfiles:
        if not re.search(reg, f):
            continue
        lst.append(f)

    # Recursively call add all vala files of subdirectories to list
    for d in subdirs:
        lst.extend(vala_files(d))

    return lst

if __name__ == '__main__':
    main()
