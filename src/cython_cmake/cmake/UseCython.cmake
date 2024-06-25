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
