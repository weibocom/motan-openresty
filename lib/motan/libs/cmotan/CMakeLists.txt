cmake_minimum_required(VERSION 3.6)
project(motan_lua)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DNODEBUG -std=c99 -Wall -Wextra")

execute_process(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        COMMAND git rev-parse --is-inside-work-tree
        RESULT_VARIABLE GIT_PROJECT OUTPUT_QUIET ERROR_QUIET)
if (${GIT_PROJECT} EQUAL 0)
    execute_process(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
            COMMAND git rev-parse HEAD
            OUTPUT_VARIABLE GIT_REVISION
            OUTPUT_STRIP_TRAILING_WHITESPACE)
    message(STATUS "In a git repository we will define the MOTAN_REVISION with ${GIT_REVISION}")
    add_definitions(-DMOTAN_REVISION=" rev-git-${GIT_REVISION}")
endif ()

# suppress warnig from glibc with old version
add_definitions(-D_DEFAULT_SOURCE)
add_definitions(-D_BSD_SOURCE)

file(COPY ${CMAKE_SOURCE_DIR}/test.lua DESTINATION ${CMAKE_BINARY_DIR})

# we use luajit 2.0 to compile, the generated library still can running with luajit-2.1
include_directories(src /usr/local/include/luajit-2.0)
# we should use case sensitive package name for linux
set(SOURCE_FILES src/serialization.c src/buffer.c)

add_library(motan_shared SHARED ${SOURCE_FILES})
SET_TARGET_PROPERTIES(motan_shared PROPERTIES OUTPUT_NAME "motan")
target_link_libraries(motan_shared luajit-5.1)

add_executable(buffer_unittest src/buffer_unittest.c)
target_link_libraries(buffer_unittest motan_shared)

add_executable(serialization_unittest src/serialization_unittest.c)
target_link_libraries(serialization_unittest luajit-5.1)

