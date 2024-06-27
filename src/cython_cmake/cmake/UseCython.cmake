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
#                     [LANGUAGE C | CXX]
#                     [CYTHON_ARGS <args> ...]
#                     [OUTPUT <OutputFile>]
#                     [OUTPUT_VARIABLE <OutputVariable>]
#                     )
#
# Options:
#
# ``LANGUAGE [C | CXX]``
#   Force the generation of either a C or C++ file. Recommended; will attempt
#   to be deduced if not specified, defaults to C unless only CXX is enabled.
#
# ``CYTHON_ARGS <args>``
#   Specify additional arguments for the cythonization process. Will default to
#   the ``CYTHON_ARGS`` variable if not specified.
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

if(CMAKE_VERSION VERSION_LESS "3.7")
  message(FATAL_ERROR "CMake 3.7 required for DEPFILE")
endif()


function(Cython_compile_pyx)
  cmake_parse_arguments(
    PARSE_ARGV 0
    CYTHON
    ""
    "OUTPUT;LANGUAGE;OUTPUT_VARIABLE"
    "CYTHON_ARGS"
    )
  set(ALL_INPUT ${CYTHON_UNPARSED_ARGUMENTS})
  list(LENGTH ALL_INPUT INPUT_LENGTH)
  if(NOT INPUT_LENGTH EQUAL 1)
    message(FATAL_ERROR "One and only one input file must be specified, got '${ALL_INPUT}'")
  endif()
  list(GET ALL_INPUT 0 INPUT)

  # Set target language
  if(NOT CYTHON_LANGUAGE)
    get_property(_langauges GLOBAL PROPERTY ENABLED_LANGUAGES)

    if("C" IN_LIST _langauges AND "CXX" IN_LIST _langauges)
      # Try to compute language. Returns falsy if not found.
      _cython_compute_language(CYTHON_LANGUAGE ${INPUT})
      message(STATUS "${CYTHON_LANGUAGE}")
    elseif("C" IN_LIST _langauges)
      # If only C is enabled globally, assume C
      set(CYTHON_LANGUAGE C)
    elseif("CXX" IN_LIST _langauges)
      # Likewise for CXX
      set(CYTHON_LANGUAGE CXX)
    else()
      message(FATAL_ERROR "LANGUAGE keyword required if neither C nor CXX enabled globally")
    endif()
  endif()

  # Default to C if not found
  if(NOT CYTHON_LANGUAGE)
    set(CYTHON_LANGUAGE C)
  endif()

  if(CYTHON_LANGUAGE STREQUAL C)
    set(language_arg "")
    set(langauge_ext ".c")
  elseif(CYTHON_LANGUAGE STREQUAL CXX)
    set(language_arg "--cplus")
    set(langauge_ext ".cxx")
  else()
    message(FATAL_ERROR "cython_compile_pyx LANGUAGE must be one of C or CXX")
  endif()

  # Place the cython files in the current binary dir if no path given
  # Can use cmake_path for CMake 3.20+
  if(NOT CYTHON_OUTPUT)
    get_filename_component(basename "${INPUT}" NAME_WE)

    set(CYTHON_OUPUT "${CMAKE_CURRENT_BINARY_DIR}/${basename}${langauge_ext}")
  endif()

  get_filename_component(CYTHON_OUTPUT "${CYTHON_OUPUT}" ABSOLUTE)

  # Normalize the input path
  get_filename_component(INPUT "${INPUT}" ABSOLUTE)
  set_source_files_properties("${INPUT}" PROPERTIES GENERATED TRUE)

  # Support
  if(NOT CYTHON_CYTHON_ARGS AND DEFINED CYTHON_ARGS)
    set(CYTHON_CYTHON_ARGS "${CYTHON_ARGS}")
  endif()

  # Output variable only if set
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
    COMMAND
      Cython::Cython
      ${language_arg}
      ${CYTHON_CYTHON_ARGS}
      --depfile
      "${INPUT}"
      --output-file "${CYTHON_OUTPUT}"
    MAIN_DEPENDENCY
      "${INPUT}"
    DEPFILE
      "${depfile_path}"
    VERBATIM
    COMMENT
    "Cythonizing source ${input_file_relative} to output ${generated_file_relative}"
  )
endfunction()

function(_cython_compute_language OUTPUT_VARIABLE FILENAME)
  file(READ "${FILENAME}" FILE_CONTENT)
  set(REGEX_PATTERN [=[^[[:space:]]*#[[:space:]]*distutils:.*language[[:space:]]*=[[:space:]]*(c\\+\\+|c)]=])
  string(REGEX MATCH "${REGEX_PATTERN}" MATCH_RESULT "${FILE_CONTENT}")
  string(TOUPPER "${MATCH_RESULT}" LANGUAGE_NAME)
  string(REPLACE "+" "X" LANGUAGE_NAME "${LANGUAGE_NAME}")
  set(${OUTPUT_VARIABLE} ${LANGUAGE_NAME} PARENT_SCOPE)
endfunction()
