# CMAKE generated file: DO NOT EDIT!
# Generated by "MSYS Makefiles" Generator, CMake Version 3.14

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /X/tools/cmake/bin/cmake.exe

# The command to remove a file.
RM = /X/tools/cmake/bin/cmake.exe -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /X/tools/luapower-full/csrc/libjpeg/src

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /X/tools/luapower-full/csrc/libjpeg/src

# Utility rule file for tarball.

# Include the progress variables for this target.
include CMakeFiles/tarball.dir/progress.make

CMakeFiles/tarball:
	sh pkgscripts/maketarball

tarball: CMakeFiles/tarball
tarball: CMakeFiles/tarball.dir/build.make

.PHONY : tarball

# Rule to build all files generated by this target.
CMakeFiles/tarball.dir/build: tarball

.PHONY : CMakeFiles/tarball.dir/build

CMakeFiles/tarball.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/tarball.dir/cmake_clean.cmake
.PHONY : CMakeFiles/tarball.dir/clean

CMakeFiles/tarball.dir/depend:
	$(CMAKE_COMMAND) -E cmake_depends "MSYS Makefiles" /X/tools/luapower-full/csrc/libjpeg/src /X/tools/luapower-full/csrc/libjpeg/src /X/tools/luapower-full/csrc/libjpeg/src /X/tools/luapower-full/csrc/libjpeg/src /X/tools/luapower-full/csrc/libjpeg/src/CMakeFiles/tarball.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/tarball.dir/depend

