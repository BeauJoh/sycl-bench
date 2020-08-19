#include <cstdio>
#include <vector>

#include <common.h>
//#define PRINT_MATRIX
//#define MATRIX_TEST

// Performs matrix multiply of the form (AB)

template <typename T>
class MatmulBKP;

template <typename T>
void multiply(cl::sycl::queue& queue, cl::sycl::buffer<T, 2>& mat_a, cl::sycl::buffer<T, 2>& mat_b,
    cl::sycl::buffer<T, 2>& mat_c, const size_t mat_size) {
  queue.submit([&](cl::sycl::handler& cgh) {
    auto a = mat_a.template get_access<cl::sycl::access::mode::read>(cgh);
    auto b = mat_b.template get_access<cl::sycl::access::mode::read>(cgh);
    auto c = mat_c.template get_access<cl::sycl::access::mode::discard_write>(cgh);

		cgh.parallel_for<class MatmulBKP<T>>(cl::sycl::range<2>(mat_size, mat_size), [=](cl::sycl::item<2> item) {
            //printf("id:%zu\n",item.get_linear_id());

			auto sum = 0;
			for(size_t k = 0; k < mat_size; ++k) {
				const auto a_ik = a[{item[0], k}];
				const auto b_kj = b[{k, item[1]}];
				sum += a_ik * b_kj;
			}
			c[item] = sum;
		});
  });
}


template <typename T>
class MatmulBKP {
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
	MatmulBKP(const BenchmarkArgs &_args) : args(_args) {
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
        args.local_size = 2;
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
		multiply(args.device_queue, mat_a_buf.get(), mat_b_buf.get(), mat_res_buf.get(), mat_size);
	}

  static std::string getBenchmarkName() {
      std::stringstream name;
      name << "MatMul_BKP_";
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
	app.run< MatmulBKP<float> >();
}
