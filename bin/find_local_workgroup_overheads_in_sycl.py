#!/usr/bin/env python3

import os
import os.path
import subprocess
import sys
import copy
import timeit

def create_log_range(begin, end):
  result = [begin]
  current = begin
  while current < end:
    current *= 2
    result += [current]
    
  return result

def turn_off_opencl():
    try:
        os.rename("/etc/OpenCL/vendors/nvidia.icd", "/etc/OpenCL/vendors/nvidia.icdX")
        os.rename("/etc/OpenCL/vendors/amd.icd", "/etc/OpenCL/vendors/amd.icdX")
    except:
        print("Couldn't disable OpenCL")

def turn_on_opencl():
    try:
        os.rename("/etc/OpenCL/vendors/amd.icdX", "/etc/OpenCL/vendors/amd.icd")
    except:
        print("Couldn't disable OpenCL")

sycl_runtime = [#{'LD_LIBRARY_PATH':'/opt/hipSYCL/llvm/lib', 'directory':'serial-build-hipsycl-cpu', 'runtime':'hipSYCL-cpu'},
                {'LD_LIBRARY_PATH':'/opt/hipSYCL/llvm/lib', 'directory':'new-build-hipsycl-cpu', 'runtime':'hipSYCL-cpu'},
                #{'LD_LIBRARY_PATH':'/tmp/llvm-sycl/build/lib', 'directory':'new-build-dpc++-cpu', 'runtime':'DPC++-cpu'},
                #{'LD_LIBRARY_PATH':'', 'directory':'new-build-trisycl-cpu','runtime':'triSYCL-cpu'},
                #{'LD_LIBRARY_PATH':'/tmp/ComputeCpp-latest/lib', 'directory':'new-build-computecpp','runtime':'ComputeCPP-cpu'},
                #{'LD_LIBRARY_PATH':'/tmp/ComputeCpp-latest/lib', 'directory':'new-build-computecpp','runtime':'ComputeCPP-opencl'},
                ]
benchmark_executable = 'vec_add_wgp' #'vec_add_serial'

options = { '--size' : create_log_range(2**30, 2**30),
            '--num-runs' : 100,
            '--output' : './local_workgroup_overheads_with_sycl_implementations.csv'
        }


for runtime in sycl_runtime:
    this_executable = './' + runtime['directory'] + '/' + benchmark_executable
    if runtime['runtime'] == "ComputeCPP-opencl":
        turn_on_opencl()
    os.environ['LD_LIBRARY_PATH'] = runtime['LD_LIBRARY_PATH']

    print("Running: " + this_executable)
    for size in options['--size']:
        print("Size: " + str(size))
        for localsize in create_log_range(2**8, size):
            print("Local Size: " + str(localsize))
            print("OMP_NUM_THREADS=" + str(int(size/localsize)))
            args = []
            for arg in options:
              if not isinstance(options[arg], list):
                args.append(str(arg)+'='+str(options[arg]))
            args.append('--size='+str(size))
            args.append('--local='+str(localsize))
            print(args)
            retcode = subprocess.call([this_executable]+args)
            if retcode != 0:
              print("Benchmark failed, aborting run")
              break

    #clean up after ourself
    if runtime['runtime'] == "ComputeCPP-opencl":
        turn_off_opencl()

#vec_add --num-runs=250 --output=./sycl-bench.csv --size=262144 --local=256
