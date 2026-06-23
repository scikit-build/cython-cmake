if(CMAKE_Cython_COMPILER_FORCED)
    # The compiler configuration was forced by the user.
    # Assume the user has configured all compiler information.
    set(CMAKE_Cython_COMPILER_WORKS TRUE)
    return()
endif()

include(CMakeTestCompilerCommon)

unset(CMAKE_Cython_COMPILER_WORKS CACHE)

if(NOT CMAKE_Cython_COMPILER_WORKS)
    PrintTestCompilerStatus(Cython)
    try_compile(CMAKE_Cython_COMPILER_WORKS
            SOURCES ${CMAKE_CURRENT_LIST_DIR}/TestCythonCompiler.pyx
            OUTPUT_VARIABLE __CMAKE_Cython_COMPILER_OUTPUT
    )
    set(CMAKE_Cython_COMPILER_WORKS ${CMAKE_Cython_COMPILER_WORKS})
    unset(CMAKE_Cython_COMPILER_WORKS CACHE)
    if(NOT CMAKE_Cython_COMPILER_WORKS)
        PrintTestCompilerResult(CHECK_FAIL "broken")
        message(FATAL_ERROR
            "The Cython compiler\n  \"${CMAKE_Cython_COMPILER}\"\n"
            "is not able to compile a simple test program.\nIt fails with the following output:\n"
            "  ${__CMAKE_Cython_COMPILER_OUTPUT}\n")
    endif()
    PrintTestCompilerResult(CHECK_PASS "works")
    set(Cython_TEST_WAS_RUN 1)
endif()
