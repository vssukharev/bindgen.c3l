
// # define LLVM_ATTRIBUTE_C_DEPRECATED(decl, message) \
//   decl __attribute__((deprecated))
//
// LLVM_ATTRIBUTE_C_DEPRECATED(
//   LLVMValueRef LLVMBuildNUWNeg(LLVMBuilderRef B, LLVMValueRef V, const char *Name)
//   , "Use LLVMBuildNeg + LLVMSetNUW instead.");

struct Hello {
  struct { int a; }* dsa;
  enum {
    ONE, 
    TWO, 
    THREE
  }* _kind1;
  enum Ee {
    ONE1, 
    TWO1, 
    THREE1
  }* _kind2;
  struct UnknownT* ut;
};


