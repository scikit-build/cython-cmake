cmake_minimum_required(VERSION 3.15...3.29)
project(${SKBUILD_PROJECT_NAME} LANGUAGES CXX)

find_package(
  Python
  COMPONENTS Interpreter Development.Module
  REQUIRED)
find_package(Cython MODULE REQUIRED VERSION 3.0)
include(UseCython)

# A C++ library you build yourself. This could equally be brought in with
# add_subdirectory() or find_package() for an external library.
add_library(mylib STATIC mylib.cpp)
target_include_directories(mylib PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
# Needed so the static library can be linked into the shared extension module.
set_target_properties(mylib PROPERTIES POSITION_INDEPENDENT_CODE ON)

# Transpile the Cython wrapper to C++ ...
cython_transpile(wrapper.pyx
  LANGUAGE CXX
  OUTPUT_VARIABLE wrapper_cxx
)

# ... then build it into an extension module linked against the C++ library.
python_add_library(wrapper MODULE "${wrapper_cxx}" WITH_SOABI)
target_link_libraries(wrapper PRIVATE mylib)

install(TARGETS wrapper DESTINATION .)
