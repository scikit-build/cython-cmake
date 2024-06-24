cmake_minimum_required(VERSION 3.20...3.26)
project(${SKBUILD_PROJECT_NAME} LANGUAGES C)

find_package(
  Python
  COMPONENTS Interpreter Development.Module
  REQUIRED)
find_package(Cython MODULE REQUIRED VERSION 3.0)

cython_compile_pyx(simple.pyx LANGUAGE C OUTPUT_VARIABLE simple_c)

python_add_library(simple MODULE "${simple_c}" WITH_SOABI)

install(TARGETS simple DESTINATION .)
