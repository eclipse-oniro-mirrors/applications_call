# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(call_recorder)

add_link_options(-s)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

add_library(callrecorder SHARED NapiInit.cpp napi/callRecorder.cpp)
target_link_libraries(callrecorder PUBLIC libace_napi.z.so)
target_link_libraries(callrecorder PUBLIC libhilog_ndk.z.so)