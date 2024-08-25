message(WARNING "Entering CMakeDetermineCythonCompiler.cmake")

find_package(Python 3.8 REQUIRED Interpreter Development.Module)
find_program(CYTHON_EXE
        cython
        REQUIRED
)

#include(${CMAKE_ROOT}/Modules/CMakeDetermineCompiler.cmake)
##include(Platform/${CMAKE_SYSTEM_NAME}-Determine-Cython OPTIONAL)
##include(Platform/${CMAKE_SYSTEM_NAME}-Cython OPTIONAL)
#if(NOT CMAKE_Cython_COMPILER_NAMES)
#  set(CMAKE_Cython_COMPILER_NAMES cython)
#endif()

## Build a small source file to identify the compiler.
#if(NOT CMAKE_Cython_COMPILER_ID_RUN)
#  set(CMAKE_Cython_COMPILER_ID_RUN 1)
#
#  # Try to identify the compiler.
#  set(CMAKE_Cython_COMPILER_ID)
#  include(${CMAKE_ROOT}/Modules/CMakeDetermineCompilerId.cmake)
#  CMAKE_DETERMINE_COMPILER_ID(Cython CYTHONFLAGS CMakeCythonCompilerId.pyx)
#
#  execute_process(COMMAND "${CMAKE_Cython_COMPILER}" "/help /preferreduilang:en-US" OUTPUT_VARIABLE output)
#  string(REPLACE "\n" ";" output "${output}")
#  foreach(line ${output})
#    string(TOUPPER ${line} line)
#    string(REGEX REPLACE "^.*COMPILER.*VERSION[^\\.0-9]*([\\.0-9]+).*$" "\\1" version "${line}")
#    if(version AND NOT "x${line}" STREQUAL "x${version}")
#      set(CMAKE_Cython_COMPILER_VERSION ${version})
#      break()
#    endif()
#  endforeach()
#  message(STATUS "The Cython compiler version is ${CMAKE_Cython_COMPILER_VERSION}")
#endif()

# configure variables set in this file for fast reload later on
configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeCythonCompiler.cmake.in
  ${CMAKE_PLATFORM_INFO_DIR}/CMakeCythonCompiler.cmake
  @ONLY
  )
