cmake_minimum_required(VERSION 3.15...3.29)
set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "")
project(${SKBUILD_PROJECT_NAME} LANGUAGES C Cython)

#find_package(
#  Python
#  COMPONENTS Interpreter Development.Module
#  REQUIRED)

python_add_library(simple MODULE WITH_SOABI)
target_sources(simple PRIVATE simple.pyx)

install(TARGETS simple DESTINATION .)
