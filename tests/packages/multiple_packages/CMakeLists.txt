cmake_minimum_required(VERSION 3.15...3.29)
project(${SKBUILD_PROJECT_NAME} LANGUAGES C)

find_package(
  Python
  COMPONENTS Interpreter Development.Module
  REQUIRED)
find_package(Cython MODULE REQUIRED VERSION 3.0)
include(UseCython)

#-----------------------------------------------------------------------------
# package1.module
cython_transpile(package1/module.pyx
  LANGUAGE C
  OUTPUT_VARIABLE module_c
)

python_add_library(module1 MODULE "${module_c}" WITH_SOABI)

install(TARGETS module1 DESTINATION "package1")

#-----------------------------------------------------------------------------
# package1.package2.module
cython_transpile(package1/package2/module.pyx
  LANGUAGE C
  OUTPUT_VARIABLE module_c
)

python_add_library(module2 MODULE "${module_c}" WITH_SOABI)

install(TARGETS module2 DESTINATION "package1/package2")

#-----------------------------------------------------------------------------
# package1.package3.module

file(COPY package1/package2/module.pyx DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/..)

cython_transpile(${CMAKE_CURRENT_SOURCE_DIR}/../module.pyx
  LANGUAGE C
  CYTHON_ARGS
    --module-name "package1.package3.module"
  OUTPUT_VARIABLE module_c
)

python_add_library(module3 MODULE "${module_c}" WITH_SOABI)

install(TARGETS module3 DESTINATION "package1/package3")
