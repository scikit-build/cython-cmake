cmake_minimum_required(VERSION 3.25...3.29)

# CYTHON_ARGS is baked into the Cython compile rule when the language is enabled,
# so it must be set before project()/enable_language(Cython). --annotate makes
# cython emit a .html report we can assert on; the extra entry exercises
# multi-value (list) handling.
set(CYTHON_ARGS --annotate -X boundscheck=False)

project(${SKBUILD_PROJECT_NAME} LANGUAGES C Cython)

find_package(
  Python
  COMPONENTS Interpreter Development.Module
  REQUIRED)

python_add_library(simple MODULE WITH_SOABI)
target_sources(simple PRIVATE simple.pyx)
# simple.pyx cimports inc/helper.pxd; forwarded to cython via <INCLUDES>.
target_include_directories(simple PRIVATE inc)

install(TARGETS simple DESTINATION .)
