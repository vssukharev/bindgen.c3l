// -> module dummy;

#define MACRO_VAL   1 /* -> const MACRO_VAL = 1; */
#define MACRO_FUN(base) base##t // unchanged

int MyFunc(float firstCase, int second_case);

typedef int(*fnPtr)(int a, float b, int);

typedef int IType;

#define ATTRIB inline

struct SomeStruct {
  double ff;
};

#define HELLO 1

int MyVar = 200 ^ 2; // -> 200 ^ 2
const int ANOTHER_CONST = 50;
const int FOO = ANOTHER_CONST + 1;

const unsigned int BAR_1 = (~0U) + HELLO;
const int BAR_2 = 0U;
const float BAR_3 = 1000.0F;
const unsigned int BAR_4 = (~0U);
const int BAR_5 = 1U;
const long long BAR_6 = (~0ULL);
const int BAR_7 = 32U;
const char BAR_8[] = "KUKU, EPTA";

typedef struct AnotherStruct_ {
  int aa;
  double bb;
} AnotherStruct;

ATTRIB void g(struct SomeStruct ASD);
