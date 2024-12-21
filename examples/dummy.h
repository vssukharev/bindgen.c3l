// -> module dummy;

#define MACRO_VAL   1 /* -> const MACRO_VAL = 1; */
#define MACRO_FUN(base) base##t // unchanged

int MyFunc(float first, double second);

typedef int(*fnPtr)(double a, float b, int);

#define ATTRIB inline

struct SomeStruct {
  double ff;
};

typedef struct {
  int aa;
  double bb;
} AnotherStruct;

ATTRIB void g(struct S asd);
