# The binary-dir-less try_compile(... SOURCES ...) used while determining the
# Cython compiler requires CMake >= 3.25.
cmake_minimum_required(VERSION 3.25...3.29)
project(${SKBUILD_PROJECT_NAME} LANGUAGES C Cython)

find_package(
  Python
  COMPONENTS Interpreter Development.Module
  REQUIRED)

python_add_library(simple MODULE WITH_SOABI)
target_sources(simple PRIVATE simple.pyx)

install(TARGETS simple DESTINATION .)
