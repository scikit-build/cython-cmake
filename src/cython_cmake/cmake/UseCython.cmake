#.rst:
#
# The following functions are defined:
#
# .. cmake:command:: add_cython_target
#
# Create a custom rule to generate the source code for a Python extension module
# using cython.
#
#   add_cython_target(<Name> [<CythonInput>]
#                     [EMBED_MAIN]
#                     [C | CXX]
#                     [PY2 | PY3]
#                     [OUTPUT_VAR <OutputVar>])
#
# ``<Name>`` is the name of the new target, and ``<CythonInput>``
# is the path to a cython source file.  Note that, despite the name, no new
# targets are created by this function.  Instead, see ``OUTPUT_VAR`` for
# retrieving the path to the generated source for subsequent targets.
#
# If only ``<Name>`` is provided, and it ends in the ".pyx" extension, then it
# is assumed to be the ``<CythonInput>``.  The name of the input without the
# extension is used as the target name.  If only ``<Name>`` is provided, and it
# does not end in the ".pyx" extension, then the ``<CythonInput>`` is assumed to
# be ``<Name>.pyx``.
#
# The Cython include search path is amended with any entries found in the
# ``INCLUDE_DIRECTORIES`` property of the directory containing the
# ``<CythonInput>`` file.  Use ``include_directories`` to add to the Cython
# include search path.
#
# Options:
#
# ``EMBED_MAIN``
#   Embed a main() function in the generated output (for stand-alone
#   applications that initialize their own Python runtime).
#
# ``C | CXX``
#   Force the generation of either a C or C++ file.  By default, a C file is
#   generated, unless the C language is not enabled for the project; in this
#   case, a C++ file is generated by default.
#
# ``PY2 | PY3``
#   Force compilation using either Python-2 or Python-3 syntax and code
#   semantics.  By default, Python-2 syntax and semantics are used if the major
#   version of Python found is 2.  Otherwise, Python-3 syntax and semantics are
#   used.
#
# ``OUTPUT_VAR <OutputVar>``
#   Set the variable ``<OutputVar>`` in the parent scope to the path to the
#   generated source file.  By default, ``<Name>`` is used as the output
#   variable name.
#
# Defined variables:
#
# ``<OutputVar>``
#   The path of the generated source file.
#
# Cache variables that affect the behavior include:
#
# ``CYTHON_ANNOTATE``
#   Whether to create an annotated .html file when compiling.
#
# ``CYTHON_FLAGS``
#   Additional flags to pass to the Cython compiler.
#
# Example usage
# ^^^^^^^^^^^^^
#
# .. code-block:: cmake
#
#   find_package(Cython)
#
#   # Note: In this case, either one of these arguments may be omitted; their
#   # value would have been inferred from that of the other.
#   add_cython_target(cy_code cy_code.pyx)
#
#   add_library(cy_code MODULE ${cy_code})
#   target_link_libraries(cy_code ...)
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

# Configuration options.
set(CYTHON_ANNOTATE OFF
    CACHE BOOL "Create an annotated .html file when compiling *.pyx.")

set(CYTHON_FLAGS "" CACHE STRING
    "Extra flags to the cython compiler.")
mark_as_advanced(CYTHON_ANNOTATE CYTHON_FLAGS)

set(CYTHON_CXX_EXTENSION "cxx")
set(CYTHON_C_EXTENSION "c")

get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)

function(add_cython_target _name)
  set(options EMBED_MAIN C CXX PY2 PY3)
  set(options1 OUTPUT_VAR)
  cmake_parse_arguments(_args "${options}" "${options1}" "" ${ARGN})

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

  set(_embed_main FALSE)

  if("C" IN_LIST languages)
    set(target_language "C")
  elseif("CXX" IN_LIST languages)
    set(target_language "CXX")
  else()
    message(FATAL_ERROR "Either C or CXX must be enabled to use Cython")
  endif()

  if(_args_EMBED_MAIN)
    set(_embed_main TRUE)
  endif()

  if(_args_C)
    set(target_language "C")
  endif()

  if(_args_CXX)
    set(target_language "CXX")
  endif()

  # Doesn't select an input syntax - Cython
  # defaults to 2 for Cython 2 and 3 for Cython 3
  set(_input_syntax "default")

  if(_args_PY2)
    set(_input_syntax "PY2")
  endif()

  if(_args_PY3)
    set(_input_syntax "PY3")
  endif()

  set(embed_arg "")
  if(_embed_main)
    set(embed_arg "--embed")
  endif()

  set(cxx_arg "")
  set(extension "c")
  if(target_language STREQUAL "CXX")
    set(cxx_arg "--cplus")
    set(extension "cxx")
  endif()

  set(language_level_arg "")
  if(_input_syntax STREQUAL "PY2")
    set(language_level_arg "-2")
  elseif(_input_syntax STREQUAL "PY3")
    set(language_level_arg "-3")
  endif()

  set(generated_file "${CMAKE_CURRENT_BINARY_DIR}/${_name}.${extension}")
  set_source_files_properties(${generated_file} PROPERTIES GENERATED TRUE)

  set(_output_var ${_name})
  if(_args_OUTPUT_VAR)
      set(_output_var ${_args_OUTPUT_VAR})
  endif()
  set(${_output_var} ${generated_file} PARENT_SCOPE)

  file(RELATIVE_PATH generated_file_relative
      ${CMAKE_BINARY_DIR} ${generated_file})

  set(comment "Generating ${target_language} source ${generated_file_relative}")
  set(cython_include_directories "")
  set(pxd_dependencies "")
  set(c_header_dependencies "")

  # Get the include directories.
  get_directory_property(cmake_include_directories
                         DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
                         INCLUDE_DIRECTORIES)
  list(APPEND cython_include_directories ${cmake_include_directories})

  # Determine dependencies.
  # Add the pxd file with the same basename as the given pyx file.
  get_source_file_property(pyx_location ${_source_file} LOCATION)
  get_filename_component(pyx_path ${pyx_location} PATH)
  get_filename_component(pyx_file_basename ${_source_file} NAME_WE)
  unset(corresponding_pxd_file CACHE)
  find_file(corresponding_pxd_file ${pyx_file_basename}.pxd
            PATHS "${pyx_path}" ${cmake_include_directories}
            NO_DEFAULT_PATH)
  if(corresponding_pxd_file)
    list(APPEND pxd_dependencies "${corresponding_pxd_file}")
  endif()

  # pxd files to check for additional dependencies
  set(pxds_to_check "${_source_file}" "${pxd_dependencies}")
  set(pxds_checked "")
  set(number_pxds_to_check 1)
  while(number_pxds_to_check GREATER 0)
    foreach(pxd ${pxds_to_check})
      list(APPEND pxds_checked "${pxd}")
      list(REMOVE_ITEM pxds_to_check "${pxd}")

      # look for C headers
      #
      #   cdef extern from "spam.h"
      #
      file(STRINGS "${pxd}" extern_from_statements
           REGEX "cdef[ ]+extern[ ]+from.*$")
      foreach(statement ${extern_from_statements})
        # Had trouble getting the quote in the regex
        string(REGEX REPLACE
               "cdef[ ]+extern[ ]+from[ ]+[\"]([^\"]+)[\"].*" "\\1"
               header "${statement}")
        unset(header_location CACHE)
        find_file(header_location ${header} PATHS ${cmake_include_directories})
        if(header_location)
          list(FIND c_header_dependencies "${header_location}" header_idx)
          if(${header_idx} LESS 0)
            list(APPEND c_header_dependencies "${header_location}")
          endif()
        endif()
      endforeach()

      # check for pxd dependencies
      # Look for cimport statements.
      #
      #   cimport dishes
      #   from dishes cimport spamdish
      #
      set(module_dependencies "")
      file(STRINGS "${pxd}" cimport_statements REGEX cimport)
      foreach(statement ${cimport_statements})
        if(${statement} MATCHES from)
          string(REGEX REPLACE
                 "from[ ]+([^ ]+).*" "\\1"
                 module "${statement}")
        else()
          string(REGEX REPLACE
                 "cimport[ ]+([^ ]+).*" "\\1"
                 module "${statement}")
        endif()
        list(APPEND module_dependencies ${module})
      endforeach()

      # check for pxi dependencies
      # Look for include statements.
      #
      #  include "spamstuff.pxi"
      #
      set(include_dependencies "")
      file(STRINGS "${pxd}" include_statements REGEX include)
      foreach(statement ${include_statements})
        string(REGEX REPLACE
               "include[ ]+[\"]([^\"]+)[\"].*" "\\1"
               module "${statement}")
        list(APPEND include_dependencies ${module})
      endforeach()

      list(REMOVE_DUPLICATES module_dependencies)
      list(REMOVE_DUPLICATES include_dependencies)

      # Add modules to the files to check, if appropriate.
      foreach(module ${module_dependencies})
        unset(pxd_location CACHE)
        find_file(pxd_location ${module}.pxd
                  PATHS "${pyx_path}" ${cmake_include_directories}
                  NO_DEFAULT_PATH)
        if(pxd_location)
          list(FIND pxds_checked ${pxd_location} pxd_idx)
          if(${pxd_idx} LESS 0)
            list(FIND pxds_to_check ${pxd_location} pxd_idx)
            if(${pxd_idx} LESS 0)
              list(APPEND pxds_to_check ${pxd_location})
              list(APPEND pxd_dependencies ${pxd_location})
            endif() # if it is not already going to be checked
          endif() # if it has not already been checked
        endif() # if pxd file can be found
      endforeach() # for each module dependency discovered

      # Add includes to the files to check, if appropriate.
      foreach(_include ${include_dependencies})
        unset(pxi_location CACHE)
        find_file(pxi_location ${_include}
                  PATHS "${pyx_path}" ${cmake_include_directories}
                  NO_DEFAULT_PATH)
        if(pxi_location)
          list(FIND pxds_checked ${pxi_location} pxd_idx)
          if(${pxd_idx} LESS 0)
            list(FIND pxds_to_check ${pxi_location} pxd_idx)
            if(${pxd_idx} LESS 0)
              list(APPEND pxds_to_check ${pxi_location})
              list(APPEND pxd_dependencies ${pxi_location})
            endif() # if it is not already going to be checked
          endif() # if it has not already been checked
        endif() # if include file can be found
      endforeach() # for each include dependency discovered
    endforeach() # for each include file to check

    list(LENGTH pxds_to_check number_pxds_to_check)
  endwhile()

  # Set additional flags.
  set(annotate_arg "")
  if(CYTHON_ANNOTATE)
    set(annotate_arg "--annotate")
  endif()

  set(cython_debug_arg "")
  set(line_directives_arg "")
  if(CMAKE_BUILD_TYPE STREQUAL "Debug" OR
     CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    set(cython_debug_arg "--gdb")
    set(line_directives_arg "--line-directives")
  endif()

  # Include directory arguments.
  list(REMOVE_DUPLICATES cython_include_directories)
  set(include_directory_arg "")
  foreach(_include_dir ${cython_include_directories})
    set(include_directory_arg
        ${include_directory_arg} "--include-dir" "${_include_dir}")
  endforeach()

  list(REMOVE_DUPLICATES pxd_dependencies)
  list(REMOVE_DUPLICATES c_header_dependencies)

  string(REGEX REPLACE " " ";" CYTHON_FLAGS_LIST "${CYTHON_FLAGS}")

  # Add the command to run the compiler.
  add_custom_command(OUTPUT ${generated_file}
                     COMMAND ${CYTHON_EXECUTABLE}
                     ARGS ${cxx_arg} ${include_directory_arg} ${language_level_arg}
                          ${embed_arg} ${annotate_arg} ${cython_debug_arg}
                          ${line_directives_arg} ${CYTHON_FLAGS_LIST} ${pyx_location}
                          --output-file ${generated_file}
                     DEPENDS ${_source_file}
                             ${pxd_dependencies}
                     IMPLICIT_DEPENDS ${target_language}
                                      ${c_header_dependencies}
                     COMMENT ${comment})

  # NOTE(opadron): I thought about making a proper target, but after trying it
  # out, I decided that it would be far too convenient to use the same name as
  # the target for the extension module (e.g.: for single-file modules):
  #
  # ...
  # add_cython_target(_module.pyx)
  # add_library(_module ${_module})
  # ...
  #
  # The above example would not be possible since the "_module" target name
  # would already be taken by the cython target.  Since I can't think of a
  # reason why someone would need the custom target instead of just using the
  # generated file directly, I decided to leave this commented out.
  #
  # add_custom_target(${_name} DEPENDS ${generated_file})

  # Remove their visibility to the user.
  set(corresponding_pxd_file "" CACHE INTERNAL "")
  set(header_location "" CACHE INTERNAL "")
  set(pxd_location "" CACHE INTERNAL "")
endfunction()
