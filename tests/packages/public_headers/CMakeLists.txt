cmake_minimum_required(VERSION 3.15...3.29)
project(${SKBUILD_PROJECT_NAME} LANGUAGES C)

find_package(
  Python
  COMPONENTS Interpreter Development.Module
  REQUIRED)
find_package(Cython MODULE REQUIRED VERSION 3.0)
include(UseCython)

# mymath.pyx has cdef public / cdef api declarations, so Cython writes
# mymath.h / mymath_api.h next to the generated source. Ask for their paths.
cython_transpile(mymath.pyx
  LANGUAGE C
  OUTPUT_VARIABLE mymath_c
  PUBLIC_HEADER_VARIABLE mymath_h
  API_HEADER_VARIABLE mymath_api_h
)

# A separate target consuming the generated public header. The explicit
# OBJECT_DEPENDS on the (now declared) header output makes the build wait for
# Cython to run and rebuild the consumer when the header changes.
add_library(consumer STATIC consumer.c)
target_link_libraries(consumer PRIVATE Python::Module)
target_include_directories(consumer PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
set_target_properties(consumer PROPERTIES POSITION_INDEPENDENT_CODE ON)
set_source_files_properties(consumer.c PROPERTIES OBJECT_DEPENDS "${mymath_h}")

python_add_library(mymath MODULE "${mymath_c}" WITH_SOABI)
target_link_libraries(mymath PRIVATE consumer)

install(TARGETS mymath DESTINATION .)
