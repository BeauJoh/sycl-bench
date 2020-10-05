# Evaluating the Performance Portability of Contemporary SYCL Implementations 

The majority of this repository is cloned from @bcosenza which offers the SYCL-Bench(mark) suite.

However, this fork provides a [Dockerfile](./Dockerfile) --for reproducibility of the 4 SYCL implementations-- and a Jupyter notebook for interpretability and to highlight our methodology around how data is collected, analysed and presented.


We also offer the source-code used in our deep-dive of the matrix multiplication example, implemented in 3 different SYCL parallel execution constructs and a serial baseline [[matmul_serial.cpp](./single-kernel/matmul_serial.cpp)]; 
basic  kernel  parallelism (BKP) [[matmul_bkp.cpp](./single-kernel/matmul_bkp.cpp)], work-group parallelism (WGP) [[matmul_wgp.cpp](./single-kernel/matmul_wgp.cpp)], and hierarchical data-parallelism (HDP) [[matmul_hdp.cpp](./single-kernel/matmul_hdp.cpp)].

The dynamic Jupyter notebook, found in [sycl-performance.ipynb](./sycl-performance.ipynb), shows how sycl-bench was run and the results are plotted from within Docker.
A static webpage of the analysis presented in the paper is found [here](./sycl-performance.html).

Docker was run with:

```docker run --device=/dev/dri --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=1 -it --mount src=`pwd`,target=/workspace,type=bind -p 8888:8888 --net=host --security-opt seccomp=unconfined --group-add video beaujoh/syclbench:latest bash```

followed by:
```beakerx --allow-root```
to start the Jupyter session.

If you have any questions about this analysis please contact me.

Beau Johnston

Computer Scientist @ Oak Ridge National Laboratory <johnstonbe@ornl.gov>

Visiting Fellow @ Australian National University <beau.johnston@anu.edu.au>

## SYCL-Bench
SYCL Benchmark Suite, work in progress

Benchmarks support the following command line arguments:
* `--size=<problem-size>` - total problem size. For most benchmarks, global range of work items. Default: 3072
* `--local=<local-size>` - local size/work group size, if applicable. Not all benchmarks use this. Default: 256
* `--num-runs=<N>` - the number of times that the problem should be run, e.g. for averaging runtimes. Default: 5
* `--device=<d>` - changes the SYCL device selector that is used. Supported values: `cpu`, `gpu`, `default`. Default: `default`
* `--output=<output>` - Specify where to store the output and how to format. If `<output>=stdio`, results are printed to standard output. For any other value, `<output>` is interpreted as a file where the output will be saved in csv format.
* `--verification-begin=<x,y,z>` - Specify the start of the 3D range that should be used for verifying results. Note: Most benchmarks do not implement this feature. Default: `0,0,0`
* `--verification-range=<x,y,z>` - Specify the size of the 3D range that should be used for verifying results. Note: Most benchmarks do not implement this feature. Default: `1,1,1`
* `--no-verification` - disable verification entirely
* `--no-ndrange-kernels` - do not run kernels based on ndrange parallel for

If you use SYCL-Bench, please cite the following papers:

@inproceedings{SYCL-Bench:Euro-Par:2020,
author = {Lal, Sohan and Alpay, Aksel and Salzmann, Philip and Cosenza, Biagio and Hirsch, Alexander and Stawinoga, Nicolai and Thoman, Peter and Fahringer, Thomas and Heuveline, Vincent},
title = {{SYCL-Bench: A Versatile Single-Source Benchmark Suite for Heterogeneous Computing}},
year = {2020},
publisher = {Springer International Publishing},
booktitle = {Accepted for publication at Euro-Par 2020: 26th International European Conference on Parallel and Distributed Computing},
series = {Euro-Par ’20}
}

@inproceedings{SYCL-Bench:IWOCL:2020,
author = {Lal, Sohan and Alpay, Aksel and Salzmann, Philip and Cosenza, Biagio and Stawinoga, Nicolai and Thoman, Peter and Fahringer, Thomas and Heuveline, Vincent},
title = {{SYCL-Bench: A Versatile Single-Source Benchmark Suite for Heterogeneous Computing}},
year = {2020},
isbn = {9781450375313},
publisher = {Association for Computing Machinery},
address = {New York, NY, USA},
url = {https://doi.org/10.1145/3388333.3388669},
doi = {10.1145/3388333.3388669},
booktitle = {Proceedings of the International Workshop on OpenCL},
articleno = {10},
numpages = {1},
keywords = {Heterogeneous Computing, SYCL Benchmarks &Runtime},
location = {Munich, Germany},
series = {IWOCL ’20}
}
