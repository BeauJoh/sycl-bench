#include <cstdio>
#include <vector>

#include <common.h>
//#define PRINT_MATRIX
//#define MATRIX_TEST

// Performs chained matrix multiply of the form (AB)(CD)
// Uses two intermediate buffers and one for the result

template <typename T>
class MatmulWGP;

template <typename T>
void multiply(cl::sycl::queue& queue, cl::sycl::buffer<T, 2>& mat_a, cl::sycl::buffer<T, 2>& mat_b, cl::sycl::buffer<T, 2>& mat_c, const size_t mat_size, const size_t local_size) {
    queue.submit([&](cl::sycl::handler& cgh) {
        auto a = mat_a.template get_access<cl::sycl::access::mode::read>(cgh);
        auto b = mat_b.template get_access<cl::sycl::access::mode::read>(cgh);
        auto c = mat_c.template get_access<cl::sycl::access::mode::discard_write>(cgh);
        //std::cout << "Problem size=" <<mat_size<< "x"<<mat_size << " # Work Groups=" <<num_workgroups<<"x"<<num_workgroups<<"("<<(num_workgroups*num_workgroups)<<")"<< " of " << workgroup_size<<"x"<<workgroup_size << " big" << std::endl;
        //compute loop
        cgh.parallel_for<class MatmulWGP<T>>(cl::sycl::nd_range<2>(cl::sycl::range<2>(mat_size,mat_size), cl::sycl::range<2>(local_size,local_size)),
            [=](cl::sycl::nd_item<2> item){
                //printf("group:%zu, local:%zu global:%zu\n",item.get_group_linear_id(), item.get_local_linear_id(), item.get_global_linear_id());

                auto sum = 0;
                for(size_t k = 0; k < mat_size; ++k) {
                    const auto a_ik = a[{item.get_global_id(0), k}];
                    const auto b_kj = b[{k, item.get_global_id(1)}];
                    sum += a_ik * b_kj;
                }
                //c[item] = sum;
                c[{item.get_global_id(0),item.get_global_id(1)}] = sum;
            });
    });
}


template <typename T>
class MatmulWGP {
protected:    
	std::vector<T> mat_a;
	std::vector<T> mat_b;
	std::vector<T> mat_res;
	BenchmarkArgs args;
	int mat_size;

	PrefetchedBuffer<T, 2> mat_a_buf;
  PrefetchedBuffer<T, 2> mat_b_buf;
  PrefetchedBuffer<T, 2> mat_res_buf;

public:
	MatmulWGP(const BenchmarkArgs &_args) : args(_args) {
		mat_size = args.problem_size;
	}

	void setup() {
#ifdef MATRIX_TEST
        //good test for 2x2 matrix:
        //mat_a = {1,2,3,4};
        //mat_b = {2,0,1,2};
        //result= {4, 4, 10, 8};
        //or: {2,4,7,10} with:
        //mat_a = {2,0,1,2};
        //mat_b = {1,2,3,4};
        args.problem_size = 2;
        args.local_size = 1;
        mat_size = 2;
        mat_a = std::vector<T>({1,2,3,4});
        mat_b = std::vector<T>({2,0,1,2});
        mat_res = std::vector<T>(mat_size * mat_size);
        mat_a_buf.initialize(args.device_queue, mat_a.data(), cl::sycl::range<2>(mat_size, mat_size));
        mat_b_buf.initialize(args.device_queue, mat_b.data(), cl::sycl::range<2>(mat_size, mat_size));
        mat_res_buf.initialize(args.device_queue, mat_res.data(), cl::sycl::range<2>(mat_size, mat_size));
        return void();
#endif
		mat_a = std::vector<T>(mat_size * mat_size);
		mat_b = std::vector<T>(mat_size * mat_size);
		mat_res = std::vector<T>(mat_size * mat_size);

		// Initialize matrices to the identity
		for(size_t i = 0; i < mat_size; ++i) {
			for(size_t j = 0; j < mat_size; ++j) {
				mat_a[i * mat_size + j] = i == j;
				mat_b[i * mat_size + j] = i == j;
			}
		}

		mat_a_buf.initialize(args.device_queue, mat_a.data(), cl::sycl::range<2>(mat_size, mat_size));
		mat_b_buf.initialize(args.device_queue, mat_b.data(), cl::sycl::range<2>(mat_size, mat_size));
		mat_res_buf.initialize(args.device_queue, mat_res.data(), cl::sycl::range<2>(mat_size, mat_size));
	}

	void run() {
		multiply(args.device_queue, mat_a_buf.get(), mat_b_buf.get(), mat_res_buf.get(), mat_size, args.local_size);
	}

  static std::string getBenchmarkName() {
      std::stringstream name;
      name << "MatMul_WGP_";
      name << ReadableTypename<T>::name;
      return name.str();
  }

  bool verify(VerificationSetting &ver) {
		// Triggers writeback
		mat_res_buf.reset();
#ifdef PRINT_MATRIX
        for(size_t i = 0; i < mat_size; ++i) {
            for(size_t j = 0; j < mat_size; ++j) {
                const T kernel_value = mat_res[i * mat_size + j];
                printf("%f\t", kernel_value);
            }
            printf("\n");
        }
#endif
#ifdef MATRIX_TEST
        return(true);
#endif
		bool verification_passed = true;

		for(size_t i = 0; i < mat_size; ++i) {
			for(size_t j = 0; j < mat_size; ++j) {
				const T kernel_value = mat_res[i * mat_size + j];
				const T host_value = i == j;
				if(kernel_value != host_value) {
					fprintf(stderr, "VERIFICATION FAILED for element %ld,%ld: %f != %f\n", i, j, kernel_value, host_value);
					verification_passed = false;
					break;
				}
			}
			if(!verification_passed) { break; }
		}
		return verification_passed;
	}
};

int main(int argc, char** argv) {
	BenchmarkApp app(argc, argv);
	
	// float 
	app.run< MatmulWGP<float> >();
}
