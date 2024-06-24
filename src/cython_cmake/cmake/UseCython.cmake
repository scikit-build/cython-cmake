#.rst:
#
# The following functions are defined:
#
# .. cmake:command:: Cython_compile_pyx
#
# Create custom rules to generate the source code for a Python extension module
# using cython.
#
#   Cython_compile_pyx(<pyx_file>
#                     LANGUAGE C | CXX
#                     [CYTHON_ARGS <args> ...]
#                     [OUTPUT <OutputFile>]
#                     [OUTPUT_VARIABLE <OutputVariable>]
#                     )
#
# Options:
#
# ``LANGUAGE [C | CXX]``
#   Force the generation of either a C or C++ file. Required.
#
# ``OUTPUT <OutputFile>``
#   Specify a specific path for the output file as ``<OutputFile>``. By
#   default, this will output into the current binary dir. A depfile will be
#   created alongside this file as well.
#
# ``OUTPUT <OutputFile>``
#   Specify a specific path for the output file as ``<OutputFile>``. By
#   default, this will output into the current binary dir. A depfile will be
#   created alongside this file as well.
#
# ``OUTPUT_VARIABLE <OutputVar>``
#   Set the variable ``<OutputVar>`` in the parent scope to the path to the
#   generated source file.
#
# Defined variables:
#
# ``<OutputVar>``
#   The path of the generated source file.
#
#
# Usage example:
#
# .. code-block:: cmake
#
#   find_package(Cython)
#
#   Cython_compile_pyx(_hello.pyx
#     LANGUAGE C
#     OUTPUT_VARIABLE _hello_source_file
#   )
#
#   Python_add_library(_hello
#     MODULE "${_hello_source_file}"
#     WITH_SOABI
#   )
#
#
# .. cmake:command:: add_cython_target
#
# Create a custom rule to generate the source code for a Python extension
# module using cython. DEPRECATED; provided for backward compatibility with
# scikit-build (classic) only.
#
#
#=============================================================================
# Copyright 2011 Kitware, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#=============================================================================

if(CMAKE_VERSION VERSION_LESS "3.20")
  message(SEND_ERROR "CMake 3.20 required")
endif()


function(add_cython_target _name)
  message(WARNING "DEPRECATED: use cython_compile_pyx instead of add_cython_target.")
  set(_options C CXX PY2 PY3)
  set(_one_value OUTPUT_VAR)
  set(_multi_value )

  cmake_parse_arguments(_args
    "${_options}"
    "${_one_value}"
    "${_multi_value}"
    ${ARGN}
    )

  # Configuration options.
  set(CYTHON_ANNOTATE OFF
      CACHE BOOL "Create an annotated .html file when compiling *.pyx.")

  set(CYTHON_FLAGS "" CACHE STRING
      "Extra flags to the cython compiler.")
  mark_as_advanced(CYTHON_ANNOTATE CYTHON_FLAGS)

  if(_args_C)
    set(_target_language "C")
  endif()
  if(_args_CXX)
    set(_target_language "CXX")
  endif()

  list(GET _args_UNPARSED_ARGUMENTS 0 _arg0)

  # if provided, use _arg0 as the input file path
  if(_arg0)
    set(_source_file ${_arg0})

  # otherwise, must determine source file from name, or vice versa
  else()
    get_filename_component(_name_ext "${_name}" EXT)

    # if extension provided, _name is the source file
    if(_name_ext)
      set(_source_file ${_name})
      get_filename_component(_name "${_source_file}" NAME_WE)

    # otherwise, assume the source file is ${_name}.pyx
    else()
      set(_source_file ${_name}.pyx)
    endif()
  endif()

  # Set additional flags.
  set(_cython_args)
  if(_args_PY2)
    list(APPEND "--2")
  endif()
  if(_args_PY3)
    list(APPEND "--3")
  endif()

  if(CYTHON_ANNOTATE)
    list(APPEND _cython_args "--annotate")
  endif()

  if(CMAKE_BUILD_TYPE STREQUAL "Debug" OR
      CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    list(APPEND _cython_args
      "--gdb"
      "--line-directives"
    )
  endif()
  string(STRIP "${CYTHON_FLAGS}" _stripped_cython_flags)
  if(_stripped_cython_flags)
    string(REGEX REPLACE " " ";" CYTHON_FLAGS_LIST "${_stripped_cython_flags}")
    list(APPEND _cython_args ${CYTHON_FLAGS_LIST})
  endif()

  Cython_compile_pyx(
    "${_source_file}"
    LANGUAGE ${_target_language}
    CYTHON_ARGS ${_cython_args}
    OUTPUT_VARIABLE ${_args_OUTPUT_VAR}
  )

  if(_args_OUTPUT_VAR)
    set(${_args_OUTPUT_VAR} ${${_args_OUTPUT_VAR}} PARENT_SCOPE)
  endif()
endfunction()

function(Cython_compile_pyx INPUT)
  cmake_parse_arguments(
    PARSE_ARGV 1
    CYTHON
    ""
    "OUTPUT;LANGUAGE;OUTPUT_VARIABLE"
    "CYTHON_ARGS"
    )

  # Set target language (required)
  if(NOT CYTHON_LANGUAGE)
    message(SEND_ERROR "cython_compile_pyx LANGUAGE keyword is required")
  elseif(CYTHON_LANGUAGE STREQUAL C)
    set(language_arg "")
    set(langauge_ext ".c")
  elseif(CYTHON_LANGUAGE STREQUAL CXX)
    set(language_arg "--cplus")
    set(langauge_ext ".cxx")
  else()
    message(SEND_ERROR "cython_compile_pyx LANGUAGE must be one of C or CXX")
  endif()

  # Place the cython files in the current binary dir if no path given
  if(NOT CYTHON_OUTPUT)
    cmake_path(GET INPUT STEM basename)
    cmake_path(APPEND CMAKE_CURRENT_BINARY_DIR "${basename}${langauge_ext}" OUTPUT_VARIABLE CYTHON_OUTPUT)
  endif()
  cmake_path(ABSOLUTE_PATH CYTHON_OUTPUT)

  # Normalize the input path
  cmake_path(ABSOLUTE_PATH INPUT)
  set_source_files_properties("${INPUT}" PROPERTIES GENERATED TRUE)


  if(CYTHON_OUTPUT_VARIABLE)
    set(${CYTHON_OUTPUT_VARIABLE} "${CYTHON_OUTPUT}" PARENT_SCOPE)
  endif()

  # Generated depfile is expected to have the ".dep" extension and be located
  # along side the generated source file.
  set(depfile_path "${CYTHON_OUTPUT}.dep")

  # Pretty-printed output name
  file(RELATIVE_PATH generated_file_relative "${CMAKE_BINARY_DIR}" "${CYTHON_OUTPUT}")
  file(RELATIVE_PATH input_file_relative "${CMAKE_SOURCE_DIR}" "${INPUT}")

  # Add the command to run the compiler.
  add_custom_command(
    OUTPUT
      "${CYTHON_OUTPUT}"
      "${depfile_path}"
    COMMAND Cython::Cython
    ARGS
      ${language_arg}
      ${CYTHON_CYTHON_ARGS}
      --depfile
      "${INPUT}"
      --output-file "${CYTHON_OUTPUT}"
    DEPENDS
      "${INPUT}"
    DEPFILE
      "${depfile_path}"
    VERBATIM
    COMMENT
    "Cythonizing source ${input_file_relative} to output ${generated_file_relative}"
  )

endfunction()
