# Locate the Cython compiler (the ``cython`` executable) so that ``Cython`` can
# be enabled as a CMake language. The actual Python development components are
# found by the consuming project (e.g. via ``find_package(Python ...)``); doing
# it here would cache an incorrect ``Python_SOABI`` because the platform suffix
# variables are not yet populated during language determination.

find_program(CYTHON_EXE
        cython
        REQUIRED
)

# Configure variables set in this file for fast reload later on.
configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeCythonCompiler.cmake.in
  ${CMAKE_PLATFORM_INFO_DIR}/CMakeCythonCompiler.cmake
  @ONLY
  )
