message(WARNING "Entering CMakeTestCythonCompiler.cmake")

if(CMAKE_Cython_COMPILER_FORCED)
    # The compiler configuration was forced by the user.
    # Assume the user has configured all compiler information.
    set(CMAKE_Cython_COMPILER_WORKS TRUE)
    return()
endif()

include(CMakeTestCompilerCommon)

unset(CMAKE_Cython_COMPILER_WORKS CACHE)

if(NOT CMAKE_Cython_COMPILER_WORKS)
    message(WARNING "Running tests: CMakeTestCythonCompiler.cmake")
    PrintTestCompilerStatus(Cython)
    unset(CMAKE_Cython_COMPILER_WORKS)
    try_compile(CMAKE_Cython_COMPILER_WORKS
            SOURCES ${CMAKE_CURRENT_LIST_DIR}/TestCythonCompiler.pyx
            OUTPUT_VARIABLE __CMAKE_Cython_COMPILER_OUTPUT
    )
    message(WARNING "__CMAKE_Cython_COMPILER_OUTPUT=${__CMAKE_Cython_COMPILER_OUTPUT}")
    unset(__TestCompiler_testCythonCompilerSource)
    set(CMAKE_Cython_COMPILER_WORKS ${CMAKE_Cython_COMPILER_WORKS})
    unset(CMAKE_Cython_COMPILER_WORKS CACHE)
    set(Cython_TEST_WAS_RUN 1)
endif()
