#include <cstdio>
#include <vector>

#include <common.h>

// Performs matrix multiply of the form (AB)
//#define PRINT_MATRIX
//#define MATRIX_TEST

template <typename T>
class MatmulSerial;

template <typename T>
void multiply(std::vector<T>& a, std::vector<T>& b,
    std::vector<T>& c, const size_t mat_size) {

    for(size_t x = 0; x < mat_size; ++x){
        for(size_t y = 0; y < mat_size; ++y){
            auto sum = 0;
            for(size_t k = 0; k < mat_size; ++k) {
                const auto a_ik = a[x * mat_size + k];
                const auto b_kj = b[k * mat_size + y];
                sum += a_ik * b_kj;
            }
            c[x * mat_size + y] = sum;
        }
    }
}


template <typename T>
class MatmulSerial {
protected:    
	std::vector<T> mat_a;
	std::vector<T> mat_b;
	std::vector<T> mat_res;
	BenchmarkArgs args;
	int mat_size;

public:
	MatmulSerial(const BenchmarkArgs &_args) : args(_args) {
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
        mat_size = 2;
        mat_a = std::vector<T>({1,2,3,4});
        mat_b = std::vector<T>({2,0,1,2});
        mat_res = std::vector<T>(mat_size * mat_size);
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
    }

	void run() {
		multiply(mat_a, mat_b, mat_res, mat_size);
	}

  static std::string getBenchmarkName() {
      std::stringstream name;
      name << "MatMul_Serial_";
      name << ReadableTypename<T>::name;
      return name.str();
  }

  bool verify(VerificationSetting &ver) {
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
	app.run< MatmulSerial<float> >();
}
