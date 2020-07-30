#########################
#  FindSYCL-GTX.cmake
#########################
#
# Tools for finding and building with SYCL-GTX.
#
# Requite CMake version 3.5 or higher

cmake_minimum_required (VERSION 3.5)
project(sycl-gtx CXX) # The name of the project (forward declare language)

if (SYCL-GTX_DIR)
    find_library(SYCL_LIB, NAME sycl-gtx, PATHS ${SYCL-GTX_DIR}/lib NO_DEFAULT_PATH)
    set(SYCL_LIB ${SYCL-GTX_DIR}/lib/libsycl-gtx.a)
    set(SYCL_INC ${SYCL-GTX_DIR}/include)
    if (EXISTS ${SYCL_LIB})
        message(STATUS "SYCL-GTX found at: ${SYCL_LIB}")
    else()
        message(FATAL_ERROR "Could NOT find sycl-gtx, please add -SYCL-GTX_DIR=/path/to/installed/sycl-gtx/ in cmake command")
    endif()
endif (SYCL-GTX_DIR)


#######################
#  add_sycl_to_target
#######################
#
#  Sets the proper flags and includes for the target compilation.
#
#  targetName : Name of the target to add a SYCL to.
#
function(add_sycl_to_target targetName)
  # Add include directories to the "#include <>" paths
  target_include_directories (${targetName} PUBLIC ${SYCL_INC})

  # Link dependencies
  target_link_libraries(${targetName} PUBLIC ${SYCL_LIB})

  target_compile_options(${targetName} PUBLIC ${OpenMP_CXX_FLAGS} -std=c++11)
endfunction(add_sycl_to_target)

