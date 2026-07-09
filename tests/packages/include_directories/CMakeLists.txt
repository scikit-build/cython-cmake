cmake_minimum_required(VERSION 3.15...3.29)
project(${SKBUILD_PROJECT_NAME} LANGUAGES C)

find_package(
  Python
  COMPONENTS Interpreter Development.Module
  REQUIRED)
find_package(Cython MODULE REQUIRED VERSION 3.0)
include(UseCython)

# helper.pxd lives in the includes/ subdir, not next to simple.pyx, so the
# cimport only resolves via INCLUDE_DIRECTORIES (relative to the source dir).
cython_transpile(simple.pyx
  LANGUAGE C
  INCLUDE_DIRECTORIES includes
  OUTPUT_VARIABLE simple_c
)

python_add_library(simple MODULE "${simple_c}" WITH_SOABI)

install(TARGETS simple DESTINATION .)
