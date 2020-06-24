# Find the DPC++ LLVM/SPIR includes and library
#
# LLVM_INCLUDE_DIR - where to find llvm include files
# LLVM_LIBRARY_DIR - where to find llvm libs
# LLVM_CFLAGS      - llvm compiler flags
# LLVM_LDFLAGS      - llvm linker flags
# LLVM_MODULE_LIBS - list of llvm libs for working with modules.
# LLVM_FOUND       - True if llvm found.
if (DPC++_INSTALL_DIR)
    find_program(SYCL_EXECUTABLE
               NAMES sycl-post-link
               DOC "sycl-post-link linker"
               PATHS ${DPC++_INSTALL_DIR}/bin NO_DEFAULT_PATH)
endif (DPC++_INSTALL_DIR)

if (SYCL_EXECUTABLE)
    message(STATUS "SYCL-LLVM sycl-post-link found at: ${SYCL_EXECUTABLE}")
else (SYCL_EXECUTABLE)
    message(FATAL_ERROR "Could NOT find sycl clang executable, please add -DDPC++_INSTALL_DIR=/path/to/installed/llvm-sycl/ in cmake command")
endif (SYCL_EXECUTABLE)

find_program(CLANG_EXECUTABLE
             NAMES clang
             DOC "clang compiler"
             PATHS ${DPC++_INSTALL_DIR}/bin NO_DEFAULT_PATH)
SET(CMAKE_C_COMPILER ${CLANG_EXECUTABLE})

find_program(CLANG++_EXECUTABLE
             NAMES clang++
             DOC "clang++ compiler"
             PATHS ${DPC++_INSTALL_DIR}/bin NO_DEFAULT_PATH)
SET(CMAKE_CXX_COMPILER ${CLANG++_EXECUTABLE})

find_program(LLVM_LINK_EXECUTABLE
             NAMES llvm-link
             DOC "llvm-link executable"
             PATHS ${DPC++_INSTALL_DIR}/bin NO_DEFAULT_PATH)
SET(CMAKE_LINKER ${LLVM_LINK_EXECUTABLE})
include_directories(${DPC++_INSTALL_DIR}/include/sycl)


#######################
#
#  Adds a SYCL compilation custom command associated with an existing
#  target and sets a dependancy on that new command.
#
#  TARGET : Name of the target to add SYCL to.
#  SOURCES : Source files to be compiled for SYCL.
#
function(add_sycl_to_target)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs TARGET)
    cmake_parse_arguments(THIS_BINARY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    set(SYCL_INCLUDE_DIR "${DPC++_INSTALL_DIR}/lib/clang/11.0.0/include/")
    set(SYCL_FLAGS "-fsycl"
                   "-fsycl-targets=nvptx64-nvidia-cuda-sycldevice"
                   "-fsycl-unnamed-lambda")

   target_include_directories(${THIS_BINARY_TARGET} PUBLIC ${SYCL_INCLUDE_DIR})

    link_directories(${DPC++_INSTALL_DIR}/lib)
    target_link_libraries(${THIS_BINARY_TARGET} sycl pi_cuda ${SYCL_FLAGS}) #otherwise use pi_opencl

    set_target_properties(${THIS_BINARY_TARGET} PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
    target_compile_options(${THIS_BINARY_TARGET} PUBLIC ${SYCL_FLAGS})

    #RUNTIME argument could be SYCL_BE=PI_CUDA

    #message("target is ${THIS_BINARY_TARGET}")
    #add_library(sycl SHARED ${THIS_BINARY_TARGET})
    #set_property(${THIS_BINARY_TARGET} ${DPC++_INSTALL_DIR}/lib)
endfunction(add_sycl_to_target)

