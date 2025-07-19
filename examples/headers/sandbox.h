
// # define LLVM_ATTRIBUTE_C_DEPRECATED(decl, message) \
//   decl __attribute__((deprecated))
//
// LLVM_ATTRIBUTE_C_DEPRECATED(
//   LLVMValueRef LLVMBuildNUWNeg(LLVMBuilderRef B, LLVMValueRef V, const char *Name)
//   , "Use LLVMBuildNeg + LLVMSetNUW instead.");

struct Hello {
  enum {
    ONE, 
    TWO, 
    THREE
  }* _kind1;
};

typedef int Flags;
typedef Flags SomeFlags;

void f(SomeFlags fs);


