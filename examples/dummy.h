// -> module dummy;

#define MACRO_VAL   1 /* -> const MACRO_VAL = 1; */
#define MACRO_FUN(base) base##t // unchanged

int MyFunc(float firstCase, int second_case);

typedef int(*fnPtr)(int a, float b, int);

#define ATTRIB inline

struct SomeStruct {
  double ff;
};

typedef struct {
  int aa;
  double bb;
} AnotherStruct;

ATTRIB void g(struct SomeStruct ASD);
