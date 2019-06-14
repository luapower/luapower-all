# This code is from the CMake FAQ

if (NOT EXISTS "X:/tools/luapower-full/csrc/libjpeg/src/install_manifest.txt")
  message(FATAL_ERROR "Cannot find install manifest: \"X:/tools/luapower-full/csrc/libjpeg/src/install_manifest.txt\"")
endif(NOT EXISTS "X:/tools/luapower-full/csrc/libjpeg/src/install_manifest.txt")

file(READ "X:/tools/luapower-full/csrc/libjpeg/src/install_manifest.txt" files)
string(REGEX REPLACE "\n" ";" files "${files}")
list(REVERSE files)
foreach (file ${files})
  message(STATUS "Uninstalling \"$ENV{DESTDIR}${file}\"")
    if (EXISTS "$ENV{DESTDIR}${file}")
      execute_process(
        COMMAND "X:/tools/cmake/bin/cmake.exe" -E remove "$ENV{DESTDIR}${file}"
        OUTPUT_VARIABLE rm_out
        RESULT_VARIABLE rm_retval
      )
    if(NOT ${rm_retval} EQUAL 0)
      message(FATAL_ERROR "Problem when removing \"$ENV{DESTDIR}${file}\"")
    endif (NOT ${rm_retval} EQUAL 0)
  else (EXISTS "$ENV{DESTDIR}${file}")
    message(STATUS "File \"$ENV{DESTDIR}${file}\" does not exist.")
  endif (EXISTS "$ENV{DESTDIR}${file}")
endforeach(file)
