# A Cython "object" is produced in two steps: cython transpiles the source to C,
# then the C compiler turns that C into the actual object file. Linking and the
# shared-library/module flags are therefore borrowed wholesale from the C
# language so that Cython targets link exactly like C targets.

if(NOT CMAKE_Cython_COMPILE_OPTIONS_PIC)
    set(CMAKE_Cython_COMPILE_OPTIONS_PIC ${CMAKE_C_COMPILE_OPTIONS_PIC})
endif()

if(NOT CMAKE_Cython_COMPILE_OPTIONS_PIE)
    set(CMAKE_Cython_COMPILE_OPTIONS_PIE ${CMAKE_C_COMPILE_OPTIONS_PIE})
endif()
if(NOT CMAKE_Cython_LINK_OPTIONS_PIE)
    set(CMAKE_Cython_LINK_OPTIONS_PIE ${CMAKE_C_LINK_OPTIONS_PIE})
endif()
if(NOT CMAKE_Cython_LINK_OPTIONS_NO_PIE)
    set(CMAKE_Cython_LINK_OPTIONS_NO_PIE ${CMAKE_C_LINK_OPTIONS_NO_PIE})
endif()

if(NOT CMAKE_Cython_COMPILE_OPTIONS_DLL)
    set(CMAKE_Cython_COMPILE_OPTIONS_DLL ${CMAKE_C_COMPILE_OPTIONS_DLL})
endif()

if(NOT DEFINED CMAKE_SHARED_LIBRARY_CREATE_Cython_FLAGS)
    set(CMAKE_SHARED_LIBRARY_CREATE_Cython_FLAGS ${CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS})
endif()

if(NOT DEFINED CMAKE_SHARED_LIBRARY_Cython_FLAGS)
    set(CMAKE_SHARED_LIBRARY_Cython_FLAGS ${CMAKE_SHARED_LIBRARY_C_FLAGS})
endif()

if(NOT DEFINED CMAKE_SHARED_LIBRARY_LINK_Cython_FLAGS)
    set(CMAKE_SHARED_LIBRARY_LINK_Cython_FLAGS ${CMAKE_SHARED_LIBRARY_LINK_C_FLAGS})
endif()

if(NOT DEFINED CMAKE_SHARED_LIBRARY_RUNTIME_Cython_FLAG)
    set(CMAKE_SHARED_LIBRARY_RUNTIME_Cython_FLAG ${CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG})
endif()

if(NOT DEFINED CMAKE_SHARED_LIBRARY_RUNTIME_Cython_FLAG_SEP)
    set(CMAKE_SHARED_LIBRARY_RUNTIME_Cython_FLAG_SEP ${CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG_SEP})
endif()

if(NOT DEFINED CMAKE_SHARED_LIBRARY_RPATH_LINK_Cython_FLAG)
    set(CMAKE_SHARED_LIBRARY_RPATH_LINK_Cython_FLAG ${CMAKE_SHARED_LIBRARY_RPATH_LINK_C_FLAG})
endif()

if(NOT DEFINED CMAKE_EXE_EXPORTS_Cython_FLAG)
    set(CMAKE_EXE_EXPORTS_Cython_FLAG ${CMAKE_EXE_EXPORTS_C_FLAG})
endif()

if(NOT DEFINED CMAKE_SHARED_LIBRARY_SONAME_Cython_FLAG)
    set(CMAKE_SHARED_LIBRARY_SONAME_Cython_FLAG ${CMAKE_SHARED_LIBRARY_SONAME_C_FLAG})
endif()


if(NOT DEFINED CMAKE_SHARED_MODULE_CREATE_Cython_FLAGS)
    set(CMAKE_SHARED_MODULE_CREATE_Cython_FLAGS ${CMAKE_SHARED_MODULE_CREATE_C_FLAGS})
endif()

if(NOT DEFINED CMAKE_SHARED_MODULE_Cython_FLAGS)
    set(CMAKE_SHARED_MODULE_Cython_FLAGS ${CMAKE_SHARED_MODULE_C_FLAGS})
endif()

if(NOT DEFINED CMAKE_EXECUTABLE_RUNTIME_Cython_FLAG)
    set(CMAKE_EXECUTABLE_RUNTIME_Cython_FLAG ${CMAKE_SHARED_LIBRARY_RUNTIME_Cython_FLAG})
endif()

if(NOT DEFINED CMAKE_EXECUTABLE_RUNTIME_Cython_FLAG_SEP)
    set(CMAKE_EXECUTABLE_RUNTIME_Cython_FLAG_SEP ${CMAKE_SHARED_LIBRARY_RUNTIME_Cython_FLAG_SEP})
endif()

if(NOT DEFINED CMAKE_EXECUTABLE_RPATH_LINK_Cython_FLAG)
    set(CMAKE_EXECUTABLE_RPATH_LINK_Cython_FLAG ${CMAKE_SHARED_LIBRARY_RPATH_LINK_Cython_FLAG})
endif()

if(NOT DEFINED CMAKE_SHARED_LIBRARY_LINK_Cython_WITH_RUNTIME_PATH)
    set(CMAKE_SHARED_LIBRARY_LINK_Cython_WITH_RUNTIME_PATH ${CMAKE_SHARED_LIBRARY_LINK_C_WITH_RUNTIME_PATH})
endif()

if(NOT CMAKE_INCLUDE_FLAG_Cython)
    set(CMAKE_INCLUDE_FLAG_Cython ${CMAKE_INCLUDE_FLAG_C})
endif()

if(NOT CMAKE_Cython_COMPILE_OBJECT)
    # First transpile <SOURCE> to <OBJECT>.c with cython, then reuse the C
    # compile rule (with its source swapped for that generated .c) to build the
    # object file.
    #
    # <INCLUDES> is forwarded to cython so that target_include_directories()
    # reaches the cythonization step (e.g. to resolve cimported .pxd files); the
    # same include dirs also reach the C compiler for headers. <FLAGS>/<DEFINES>
    # deliberately stay on the C step only: CMake fills <FLAGS> with
    # C-compilation options (PIC, build-type flags) that cython rejects.
    #
    # CYTHON_ARGS is baked in here, when the language is enabled, so it must be
    # set before project()/enable_language(Cython). It cannot ride on <FLAGS>
    # because those are consumed by the C compiler. Join into a single token:
    # COMPILE_OBJECT is itself a ';'-list of commands, so a list here would be
    # mistaken for extra commands. (One consequence: no genex support, unlike the
    # cython_transpile() function.)
    #
    # cython -M emits a gcc-style depfile next to its output (<OBJECT>.c.dep)
    # listing the .pyx and any cimported .pxd files. It has no flag to choose the
    # depfile path, so copy it onto CMake's <DEP_FILE> and declare the format
    # (below) to let the generator rebuild when a cimported .pxd changes.
    string(REPLACE "<SOURCE>" "<OBJECT>.c" CMAKE_C_COMPILE_OBJECT_replaced "${CMAKE_C_COMPILE_OBJECT}")
    string(JOIN " " _cython_args ${CYTHON_ARGS})
    set(CMAKE_Cython_COMPILE_OBJECT
            "<CMAKE_Cython_COMPILER> -M ${_cython_args} <INCLUDES> -o <OBJECT>.c <SOURCE>"
            "\"${CMAKE_COMMAND}\" -E copy <OBJECT>.c.dep <DEP_FILE>"
            "${CMAKE_C_COMPILE_OBJECT_replaced}"
    )
endif()

if(NOT DEFINED CMAKE_Cython_DEPFILE_FORMAT)
    set(CMAKE_Cython_DEPFILE_FORMAT gcc)
endif()

set(CMAKE_Cython_CREATE_SHARED_LIBRARY ${CMAKE_C_CREATE_SHARED_LIBRARY})
set(CMAKE_Cython_CREATE_SHARED_MODULE ${CMAKE_C_CREATE_SHARED_MODULE})
set(CMAKE_Cython_LINK_EXECUTABLE ${CMAKE_C_LINK_EXECUTABLE})

set(CMAKE_Cython_INFORMATION_LOADED 1)
