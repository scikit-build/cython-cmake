cmake_minimum_required(VERSION 3.15...3.29)
project(${SKBUILD_PROJECT_NAME} LANGUAGES C)

find_package(
  Python
  COMPONENTS Interpreter Development.Module
  REQUIRED)
find_package(Cython MODULE REQUIRED VERSION 3.0)
include(UseCython)

# Simulate a tool such as autopxd generating a .pxd at build time. The file does
# not exist at configure time, so the transpile must be ordered after it.
set(generated_pxd "${CMAKE_CURRENT_BINARY_DIR}/helper.pxd")
add_custom_command(
  OUTPUT "${generated_pxd}"
  COMMAND "${CMAKE_COMMAND}" -E copy
          "${CMAKE_CURRENT_SOURCE_DIR}/helper.pxd.in" "${generated_pxd}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/helper.pxd.in")
add_custom_target(generate_pxd DEPENDS "${generated_pxd}")

cython_transpile(simple.pyx
  LANGUAGE C
  CYTHON_ARGS -I "${CMAKE_CURRENT_BINARY_DIR}"
  DEPENDS generate_pxd
  OUTPUT_VARIABLE simple_c
)

python_add_library(simple MODULE "${simple_c}" WITH_SOABI)

install(TARGETS simple DESTINATION .)
