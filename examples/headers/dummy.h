// -> module dummy;

#define MACRO_VAL   1           // const MACRO_VAL = 1;
#define ONE_MORE_MACRO MACRO_VAL + 1 // const ONE_MORE_MACRO = MACRO_VAL + 1
#define MACRO_FUN(base) base##t // unchanged

int MyFunc(float firstCase, int second_case);

typedef int(*fnPtr)(int a, float b, int);

typedef int IType;

#define ATTRIB inline

struct SomeStruct {
  double ff;
};


int MyVar = 200 ^ 2; // -> 200 ^ 2

const int ANOTHER_CONST = 50;
const int FOO = ANOTHER_CONST + 1;

#define HELLO 1
const unsigned int BAR_1 = HELLO + (~0U);
const long long BAR_2 = (~0ULL);
const char BAR_3[] = "KUKU, EPTA";

typedef struct AnotherStruct_ {
  int aa;
  double bb;
} AnotherStruct;

ATTRIB void g(struct SomeStruct ASD);
